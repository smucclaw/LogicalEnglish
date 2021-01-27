:- module(_ThisFileName,[start_api_server/0]).

% API for client apps to use the reasoner and drafter

% Adapted from https://github.com/SWI-Prolog/packages-pengines/blob/master/examples/server.pl :
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_server_files)).
:- use_module(library(http/http_files)).
:- use_module(library(pengines)).
:- use_module(pengine_sandbox:library(pengines)).

:- use_module(library(http/http_json)).
:- use_module(library(http/json)).
:- use_module(library(term_to_json)).
:- use_module(library(http/http_parameters)).

:- use_module(reasoner).
:- use_module('spacy/spacy.pl').
:- use_module(drafter).
:- use_module(kp_loader).

:- if(current_module(swish)). %%%%% On SWISH:

start_api_server :- print_message(informational,"No need to start API server, SWISH already running").

:- else. % On command-line SWI-Prolog, no user restrictions:

start_api_server :- start_api_server(3050).
start_api_server(Port) :- http_server(http_dispatch, [port(Port)]).
:- endif.

:- http_handler('/taxkbapi', handle_api, []).  % this defines a web server endpoint
handle_api(Request) :-
    http_read_json_dict(Request, Payload, [value_string_as(atom)]),
    % asserta(my_request(Query)), % for debugging
    (entry_point(Payload,Result)->true;Result=_{error:"Goal failed"}),
    reply_json_dict(Result).

% Define our adhoc REST API; more general Prolog querying at
%  https://pengines.swi-prolog.org/docs/documentation.html (Javascript) or
%  https://www.swi-prolog.org/pengines/PenginesFromPython.md (Python)
% Examples (resp: true, unknown, false):
%  curl --header "Content-Type: application/json" --request POST --data '{"operation":"query", "theQuery":"a(1,Y)", "module":"https://tests.com"}' http://localhost:3050/taxkbapi
%  curl --header "Content-Type: application/json" --request POST --data '{"operation":"query", "theQuery":"testForall([1,2])", "module":"https://tests.com"}' http://localhost:3050/taxkbapi
%  curl --header "Content-Type: application/json" --request POST --data '{"operation":"query", "theQuery":"testForall([1,2,9])", "module":"https://tests.com"}' http://localhost:3050/taxkbapi
% Example with hypothetical facts:
%  curl --header "Content-Type: application/json" --request POST --data '{"operation":"query", "theQuery":"a(13,Y)", "facts":["d(13)"], "module":"https://tests.com"}' http://localhost:3050/taxkbapi
%  curl --header "Content-Type: application/json" --request POST --data '{"operation":"query", "theQuery":"a(13,Y)",  "module":"https://tests.com"}' http://localhost:3050/taxkbapi

% {operation: query, theQuery: "a(1,Y)", module:"https://tests.com"} --> {results:ResultsArray}
%   each result is a {result: true/false/unknown, bindings:VarsValuesArray, unknowns: ArrayOfTerm, why: ExplanationTerm}
entry_point(R, _{results:Results}) :- get_dict(operation,R,query), !, 
    term_string(Query,R.theQuery,[variable_names(VarPairs_)]),
    (get_dict(facts,R,Facts_) -> maplist(term_string,Facts,Facts_) ; Facts=[]),
    findall( _{bindings:VarPairs, unknowns:U, result:Result, why:E}, (
        (Facts\=[] -> ( G = (i_once_with_facts(at(Query,R.module),Facts,U_,Result__), Result__=..[Result,E_])) ; 
            G = query(at(Query,R.module),U_,taxlogExplanation(E_),Result)
            ),
        G, 
        makeBindingsDict(VarPairs_,VarPairs),
        makeUnknownsArray(U_,U),
        makeExplanationTree(E_,E)
        ), Results).

% Example:
%  curl --header "Content-Type: application/json" --request POST --data '{"operation":"draft", "pageURL":"http://mysite/page1#section2",  "content":[{"url":"http://mysite/page1#section2!chunk1", "text":"john flies by instruments"}, {"url":"http://mysite/page1#section2!chunk2", "text":"miguel drives with gusto"}]}' http://localhost:3050/taxkbapi% 
% {operation:draft, pageURL:U, content:Items} --> {pageURL:U, draft:PrologText}
%   each item is a {url:..,text:...} 
entry_point(R, _{pageURL:R.pageURL, draft:Draft}) :- get_dict(operation,R,draft), !, 
    load_content(R.content),
    draft_string(R.pageURL,Draft).


%makeBindingsDict(+NameTermPairs,-NameTermDict)
makeBindingsDict(Pairs,Dict) :-
    makeBindingsDict_(Pairs,NewPairs), dict_create(Dict,_,NewPairs).

makeBindingsDict_([Name=T|Pairs],[Name=J|NewPairs]) :- !,
    term_to_json(T,J), makeBindingsDict_(Pairs,NewPairs).
makeBindingsDict_([],[]).

makeUnknownsArray([at(X,M)|U],[_{goal:J, module:M}|NewU]) :- !,
    term_to_json(X,J), makeUnknownsArray(U,NewU).
makeUnknownsArray([],[]).


% keep in sync with reasoner.pl, namely expand_failure_trees and expand_explanation_refs
makeExplanationTree([Node|Nodes],[_{type:Type, literal:Gstring, module:M, source:Source, textOrigin:Origin, children:NewChildren}|NewNodes]) :- !,
    Node=..[Type_,G,_Ref,M,Source,Origin,Children],
    explanation_node_type(Type_,Type),
    term_string(G,Gstring),
    makeExplanationTree(Children,NewChildren),
    makeExplanationTree(Nodes,NewNodes).
makeExplanationTree([],[]).

:- http_handler('/taxkbapi/draft', handle_api_draft, []).  % this defines a web server endpoint for https://github.com/mcalejo/my-highlighter
% receive content from our highlighter Chrome extension, digest it and open a new Prolog file with its "draft":
handle_api_draft(Request) :-
    http_parameters(Request, [pageURL(PageURL_,[]),content(Content_,[])]),
    PageURL=PageURL_,
    uri_encoded(query_value,Content,Content_),
    open_string(Content,S), json_read_dict(S, ContentArray), close(S),
    load_content(ContentArray),
    draft_string(PageURL,Draft),
    url_simple(PageURL,Filename_),
    atomic_list_concat([Filename_,".pl"],Filename),
    update_gitty_file(Filename,PageURL,Draft),
    format(string(NewEditor),"/p/~a",[Filename]),
    http_redirect(see_other,NewEditor,Request).
    % reply_json_dict(_{draft:Draft, pageURL:PageURL}).
    

url_simple(URL,Simple) :- 
    parse_url(URL,L), memberchk(path(P),L), atomics_to_string(LL,'/',P), 
    ((last(LL,Simple),Simple\='') -> true ;
        append(_,[Simple,_],LL)),
    !.
url_simple(URL,URL).
