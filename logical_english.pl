:- module(_,[print_kp_le/1, le/2, le/1, test_kp_le/2, test_kp_le/1]).

:- use_module(reasoner).
:- use_module(kp_loader).
:- use_module(drafter).
:- use_module('spacy/spacy.pl').
:- use_module(library(prolog_clause)).

/*
sketch of a DCG; inadequate for an actual implementation, because we need dynamic (multiple length) terminals

rule --> conclusion, [if], conditions.

conclusion --> atomicSentence.

conditions --> condition, moreConditions.

moreConditions --> connective, condition, moreConditions.
moreConditions --> [].

connective --> {member(C,[and,or])}, [C].

condition --> [not], atomicSentence.
condition --> [it,is,not,the,case,that], atomicSentence.
condition --> atomicSentence.

% or just hack up to ternary and quaternary and quinary...
atomicSentence(Name,[A1,A2]) --> argument(A1), {le_predicate(Name,[_,_])}, [Name], argument(A2).
atomicSentence(Name,[A1,A2,A3]) --> argument(A1), {le_predicate(Name,[_,_,Arg3])}, [Name], argument(A2), [Arg3], argument(A3).

% le_predicate(Name(ArgNames))  e.g.:
%  le_predicate(owns,[_Entity,_Thing[])    le_predicate('has liability'[_Asset,'of type','with value'])
%  le_predicate('is before',[_,_])
% ...

argument(X) --> value(X).
argument(X) --> expression(X).
argument(a(Var,Type,Letter)) --> [a,Type,Letter].
argument(a(Var,Type,Letter)) --> [an,Type,Letter].
argument(a(Var,Type,_)) --> [a,Type].
argument(a(Var,Type,_)) --> [an,Type].
argument(the(Var,Type)) --> [the,Type]. % optional Letter too
argument(the(Var,Type)+(Var\=_Other)) --> [another,Type]. % ...
argument(the(Name)) --> shortVarName(Name).
*/

%%%% And now for something completely different: LE generation from Taxlog

% Ex: logical_english:test_kp_le('https://www.ato.gov.au/general/capital-gains-tax/small-business-cgt-concessions/basic-conditions-for-the-small-business-cgt-concessions/maximum-net-asset-value-test/').
test_kp_le(KP,Options) :-
    tmp_file(le,Tmp), atom_concat(Tmp, '.html', F),
    tell(F), print_kp_le(KP,Options), told, www_open_url(F).

test_kp_le(KP) :- test_kp_le(KP,[]).

% "invokes" our SWISH renderer
le(LE) :-
    le([],LE).

% Obtain navigation link to Logical English for the current SWISH editor
le(Options,logicalEnglish([HTML])) :- 
    myDeclaredModule(KP), % no need to load, it's loaded already
    le_kp_html(KP,Options,HTML).

print_kp_le(KP) :- print_kp_le(KP,[]).

print_kp_le(KP,Options) :- 
    loaded_kp(KP), le_kp_html(KP,Options,HTML), myhtml(HTML).

%%%%% LE proper
%  font-family: Arial, Helvetica, sans-serif; apparently Century Schoolbook is hot for legalese
le_kp_html(KP, Options, div(style='font-family: "Century Schoolbook", Times, serif;', [
    p(i([
        "Knowledge page carefully crafted in ", 
        a([href=EditURL,target='_blank'],"Taxlog/Prolog"), 
        " from the legislation at",br([]),
        a([href=KP,target='_blank'],KP)
        ]))| PredsHTML ]) ) :-
    retractall(option(_)), OL=[no_indefinites],
    must_succeed( forall(member(O,Options), (member(O,OL), assert(option(O)))), "Bad Logical English option, admissibles are in ~w"-[OL] ),
    retractall(reported_predicate_error(_)),
    (shouldMapModule(KP,KP_) -> true ; KP=KP_), %KP_ is the latest SWISH window module
    swish_editor_path(KP,EditURL),
    findall([\["&nbsp;"],div(style='border-style: inset',PredHTML)], (
        kp_predicate_mention(KP,Pred,defined), 
        \+ \+ le_clause(Pred,KP_,_,_), % we have more than, say, a thread_local declaration...
        findall(div(style='padding:5px;',ClauseHTML), (le_clause(Pred,KP_,_Ref,LE), le_html(LE,_,ClauseHTML)), PredHTML)
        ),PredsHTML_),
    append(PredsHTML_,PredsHTML).

le_kp_html(KP,HTML) :- 
    le_kp_html(KP,[],HTML).

:- thread_local reported_predicate_error/1, option/1.
shouldReportError(E) :- reported_predicate_error(E), !, fail.
shouldReportError(E) :- assert(reported_predicate_error(E)).

%le_html(+TermerisedLE,-PlainWordsList,-TermerisedHTMLlist)
%le_html(LE,_,_) :- mylog(LE),fail.
le_html(if(Conclusion,Conditions), RuleWords, [div(Top), div(style='padding-left:30px;',ConditionsHTML_)]) :- !,
    le_html(Conclusion,ConclusionWords,ConclusionHTML), le_html(Conditions,ConditionsWords,ConditionsHTML),
    append([ConditionsHTML, ["."]], ConditionsHTML_), % adding a dot at the end of each clause 
    append(ConclusionHTML,[span(b(' if'))], Top),
    append([ConclusionWords,[if],ConditionsWords],RuleWords). % no dot added!
%TOOO: to avoid this verbose form, generate negated predicates with Spacy help, or simply declare the negated forms
le_html(not(A),[it, is, not, the, case, that|AW],HTML) :- !, le_html(A,AW,Ahtml), HTML=["it is not the case that "|Ahtml]. 
le_html(if_then_else(Condition,true,Else),Words,HTML) :- !,
    le_html(Condition,CW,CH), le_html(Else,EW,EH), append([["{ "],CH,[" or otherwise "],EH, ["}"]],HTML),
    append([["{"],CW,[or,otherwise],EW, ["}"]],Words).
le_html(if_then_else(Condition,Then,Else),Words,HTML) :- !,
    le_html(Condition,CW,CH), le_html(Then,TW,TH), le_html(Else,EW,EH), 
    append([["{ ",b("if ")],CH,[b(" then")," it must be the case that "],TH,[b(" or otherwise ")],EH,[" }"]],HTML),
    append([["{", if],CW,[then, it, must, be, the, case, that],TW,[or, otherwise],EW,["}"]],Words).
le_html(at(Conditions,KP),Words,HTML) :- !,
    le_html(Conditions,CW,CH), le_html(KP,KPW,KPH), 
    (KPH=[HREF_]->true;HREF_='??'),
    % if we have a page, navigate to it:
    ((KP=le_argument(Word), kp(Word)) -> format(string(HREF),"/logicalEnglish?kp=~a",[Word]); HREF=HREF_),
    Label="other legislation",
    %TODO: distinguish external data, broken links...
    %(sub_atom(HREF,0,_,_,'http') -> Label="other legislation" ; Label="existing data"),
    append([CH, [span(style='font-style:italic;',[" according to ",a([href=HREF,target('_blank')],Label)])] ],HTML),
    append([CW,[according,to|KPW]],Words).
le_html(on(Conditions,Time),Words,HTML) :- !,
    (Time=a(T) -> (TimeQualifier = [" at a time "|T], TQW = [at,a,time|T]); 
        (le_html(Time,TW,TH), TimeQualifier = [" at "|TH], TQW=[at|TW]) ),
    le_html(Conditions,CW,CH), %TODO: should we swap the time qualifier for big conditions, e.g. ..., at Time, blabla
    append([CH,TimeQualifier],HTML),
    append([CW,TQW],Words).
le_html(aggregate_all(Op,Each_,SuchThat,Result),Words,HTML) :- !,
    must_succeed(Each_=le_argument(Each)),
    le_html(Result,RW,RH), le_html(SuchThat,STW,STH), 
    (Each=a(EWords) -> (EachH = ["each "|EWords], EachW=[each|EWords]) ; le_html(Each,EachW,EachH)),
    append([RH, [" is the ~w of "-[Op]],EachH,[" such that { "],STH,[" }"]],HTML),
    append([RW, [is, the, Op, of],EachW,[such, that],STW],Words).
% forall e.g. for every a Party in the Event, the Party has aggregated a Turnover and the Turnover < 10000000 and the Part is eligible
le_html(for_all(Cond, Goal), Words, HTML) :- !,
    le_html(Cond, CW, CH), le_html(Goal, GW, GH),
    append([[for, every],CW, [it, is, the, case, that],GW],Words), 
    append([[" for every "],CH, [", it is the case that {"],GH,["}"]],HTML).
% setof e.g. a Previous Owners is a collection of an Owner/ a Share where the Owner and the Share represent the ultimate owner of the Asset at the Before
le_html(set_of(Index, Cond, Set), Words, HTML) :- !,
    le_html(Index, IW, IH), le_html(Cond, CW, CH), le_html(Set, SW, SH), 
    append([SW, [is, a, set, of], IW, [where],CW],Words), 
    append([SH, [" is a collection of "],IH, [" where {"],CH,["}"]],HTML).
% propositional predicate
le_html(le_predicate(Functor,[]), Words, [span([title=Tip,style=S],HTML)]) :- !, 
    predicate_html(Functor,HTML), Words=Functor,
    atomicSentenceStyle(le_predicate(Functor,[]),Words,S,Tip).
% unary predicate
le_html(le_predicate(Functor,[Arg]), Words, [span([title=Tip,style=S],HTML)]) :- !, 
    predicate_html(Functor,PH), le_html(Arg,AW,AH), 
    append([AH,[" "],PH],HTML),
    append([AW,Functor],Words),
    atomicSentenceStyle(le_predicate(Functor,[Arg]),Words,S,Tip).
% binary 
le_html(le_predicate(Functor,[A,B]), Words, [span([title=Tip,style=S],HTML)]) :- !, 
    predicate_html(Functor,PH), le_html(A,AW,AH), le_html(B,BW,BH), 
    append([AH,[" "],PH,[" "],BH],HTML),
    append([AW,Functor,BW],Words),
    atomicSentenceStyle(le_predicate(Functor,[A,B]),Words,S,Tip).
% ternary: assume the first and third arguments are more important (subject/object)
le_html(le_predicate(Functor,[A,B,C]), Words, [span([title=Tip,style=S],HTML)]) :- !, 
    predicate_html(Functor,PH), le_html(A,AW,AH), le_html(B,BW,BH), le_html(C,CW,CH), 
    append([AH,[" "],PH,[" "],CH,[" with "],BH],HTML),
    append([AW,Functor,CW,[with|BW]],Words),
    atomicSentenceStyle(le_predicate(Functor,[A,C]),Words,S,Tip). % fake a sentence with the predicate as binary
le_html(le_predicate(Functor,[A1|Args]), Words, [span([title=Tip,style=S],HTML)]) :- !, 
    predicate_html(Functor,PH), le_html(A1,A1W,A1H),
    findall([", "|AH]/AW, (member(A,Args),le_html(A,AW,AH)), Pairs),
    findall(AH,member(AH/_,Pairs),ArgsH_),
    findall(AW,member(_/AW,Pairs),ArgsW_),
    append(ArgsH_,ArgsH), append(ArgsW_,ArgsW),
    append([PH,[" ( "],A1H,ArgsH,[")"]],HTML),
    append([Functor,["("],A1W,ArgsW,[")"]],Words),
    atomicSentenceStyle(le_predicate(Functor,[A1|Args]),Words,S,Tip).
le_html(le_template(Template, Args), Words, [span([title=Tip,style=S],HTML)]) :- !, 
    dict([_|OriginalArgs], _, Template), 
    le_fill_template(Template, Template, OriginalArgs, Args, Words, HTML),
    atomicSentenceStyle(le_predicate(Template, Args), Words, S, Tip).
le_html(le_argument(X),Words,HTML) :- !,
    le_html(X,Words,HTML).
le_html(a(Words), TheWords, HTML) :- !, 
    var_style(VS), atomics_to_string(Words," ",Name), atom_chars(Name,[First|_]),
    (member(First,[a,e,i,o,u,'A','E','I','O','U']) -> Det=an ; Det=a),
    (option(no_indefinites) -> (HTML=[span(VS,[Name])], TheWords=Words) ; 
        (HTML = [span(VS,[Det," ",Name])], TheWords=[Det|Words])
        ).
le_html(the(Words), TheWords, [span(VS,["the ",Name])]) :- !, 
    var_style(VS), atomics_to_string(Words," ",Name),
    TheWords = [the|Words].
le_html(L,Words,["[",span(LH),"]"]) :- is_list(L), !, 
    findall([","|XH]/XW, (member(X,L), le_html(X,XW,XH)), Pairs), 
    findall(XH,member(XH/_,Pairs),LHS),
    append(LHS,LH_), 
    findall(XW,member(_/XW,Pairs),Xwords_),
    append(Xwords_,Xwords),
    (LH_=[] -> (LH=[""], Words=["[]"]); 
        ( LH_=[_Comma|LH], append(['['|Xwords],[']'],Words))
    ).
le_html(LE,Words,["~w"-[LE]]) :- atomic(LE), !, Words=[LE].
le_html(LE,[Word],["~w"-[LE]]) :- compound(LE), compound_name_arity(LE,F,0), !, format(string(Word),"~w()",[F]).
le_html(Binary, Words, HTML) :- compound(Binary), compound_name_arguments(Binary,Op,[A,B]), member(Op,[and,or]), !, 
    le_html(A,AW,Ahtml), le_html(B,BW,Bhtml), 
    %length(AW,LA), length(BW,LB),
    (Op==or -> HTML = [div(Ahtml),b(" ~w "-[Op]),div(Bhtml)] ; 
        append([Ahtml,[b(" ~w "-[Op])],Bhtml],HTML) 
    ),
    append([AW,[Op],BW],Words).
le_html(Term,Words,HTML) :- compound(Term), compound_name_arguments(Term,F,[A,B]), infixOperator(F), !, 
    le_html(A,AW,AH), le_html(B,BW,BH),
    append([AH,[" ~a "-[F]],BH],HTML),
    append([AW,[F],BW],Words).
le_html(Term,Words,HTML) :- compound(Term), compound_name_arguments(Term,F,[A]), prefixOperator(F), !, 
    le_html(A,AW,AH), 
    append([[" ~a "-[F]],AH],HTML),
    append([[F],AW],Words).
le_html(Term,Words,HTML) :- compound(Term), !, 
    compound_name_arguments(Term,F,Args), 
    %TODO: represent functions explicitly?
    findall([","|AH]/AW,(member(A,Args), le_html(le_argument(A),AW,AH)),Pairs),
    findall(AH,member(AH/_,Pairs),ArgsH_),
    findall(AW,member(_/AW,Pairs),ArgsW_),
    append(ArgsH_,[_Hack|ArgsH]), % remove the first comma
    append(ArgsW_,ArgsW),
    append([[F],["("],ArgsH,[")"]],HTML),
    append([[F],["("],ArgsW,[")"]],Words).
le_html(LE,[Word],["?~w?"-[LE]]) :- format(string(Word),"~w",[LE]). 

le_fill_template(Words, HTML, [], _, Words, HTML)  :- !.
le_fill_template(TemplateW, TemplateH, [V1|RV], [A1|Args], Words, HTML) :- 
    le_html(A1,A1W,A1H),
    le_replace(TemplateW, V1, A1W, NewTemplateW),
    le_replace(TemplateH, V1, A1H, NewTemplateH), 
    le_fill_template(NewTemplateW, NewTemplateH, RV, Args, Words, HTML). 

le_replace([], _, _, []) :- !.
le_replace([T1|RestTemp], V, Arg, [T1,' '|NewTemp]) :-
    T1 \== V,
    le_replace(RestTemp, V, Arg, NewTemp).
le_replace([T1|RestTemp], V, Arg, NewTemp) :-
    T1 == V,
    le_replace(RestTemp, V, Arg, Temp),
    append(Arg, Temp, NewTemp). 

infixOperator(Op) :- current_op(_,Type,Op), member(Type,[xfx,xfy,yfx]), !.
prefixOperator(Op) :- current_op(_,Type,Op), member(Type,[xf,yf]), !.

predicate_html(Words,[b(Name)]) :- atomics_to_string(Words, " ", Name).

var_style(style="color:#880000").

% from https://www.phpied.com/curly-underline/
bad_style('background: url(taxkb/underline.gif) bottom repeat-x;').

%! atomicSentenceStyle(+LEPredicate,+Words,-StyleString,-Tip)
%  Uses Spacy to form an opinion on the writing style, reporting it as either empty ('') or curly underline plus a text tip
%  Only the first occurrence gets a red curlyline, but all get the tooltip
atomicSentenceStyle(le_predicate([F],Args),_Words,S,Tip) :- length(Args,Arity), functor(Pred,F,Arity), system_predicate(Pred), !,
    %TODO: this misses system predicates with multiple words
    S='', Tip="system predicate".
atomicSentenceStyle(le_predicate(_F,_Args),_Words,'',"Simplest style") :- !. % Testing without spacy
atomicSentenceStyle(le_predicate(Functor,[_,_,_|_]),_Words,S,Tip) :- !, % arity>=3, no point in parsing it all
    bad_style(BS),
    once(( spaCyParseTokens(Functor,_,Tokens), member_with([dep=root,pos=POS,lemma=Lemma],Tokens))),
    (POS==verb -> (S='', Tip="verb 'to ~a'"-Lemma) ; 
    (   (shouldReportError(missing_verb(Functor,POS,Lemma)) -> S=BS ; S=''), 
        Tip="predicate should have a verb, has a ~a instead (~a)"-[POS,Lemma] )
    ).
atomicSentenceStyle(le_predicate(Functor,_),Words,S,Tip) :- 
    findall(SI/Tokens,spaCyParseTokens(Words,SI,Tokens),Sentences),
    bad_style(BS),
    (Sentences=[_/Tokens] -> (
        member_with([dep=root,pos=POS,lemma=Lemma],Tokens),
        (POS==verb -> (S='', Tip="verb 'to ~a'"-Lemma) ; 
            (
                (shouldReportError(missing_verb(Functor,POS,Lemma)) -> S=BS ; S=''),  
                Tip="predicate sentence should have a verb, has a ~a instead (~a)"-[POS,Lemma] )
        )
        );
        (S = BS,length(Sentences,NS),Tip="predicate sentence too complicated (~w sentences)"-[NS])
    ).


%le_clause(?H,+Module,-Ref,-LEterm)
% H is a predicate head, with or without time; if the rule has explicit time in head, time will be explicit in the LE too
% LEterms:
%  if(Conclusion,Conditions), or/and/not/must(Condition,Obligation), if_then_else(Condition,Then,Else)
%   le_predicate(FunctorWords,Args); each Arg is a le_argument(Term), where term is a/the(Words) or le_some_thing (anonymous var) or Term
%   le_predicate(the(Words),unknown_arguments) for meta variables :-)
%   true/false
%   aggregate_all(Operator,Each,Condition,Result)
%   at(Predicate,KP)  ...Predicate (cf. RefLink)...
%   on(Predicate,TimeExpression) ...Predicate at time ...
%TODO: return explicit time on the head
le_clause(H,M,Ref,LE) :-
    must_be(nonvar,H),
    myClause(H,M,_,Ref), 
    % hacky code extracted from clause_info/2, to make sure we do not get confused with anonymous variables 
    % (which are ommited from the variable names list)
    clause_property(Ref,file(File)), File\==user, clause_property(Ref,line_count(LineNo)),
    prolog_clause:read_term_at_line(File, LineNo, M, Clause_, _TermPos0, VarNames),
    expand_term(Clause_,RawClause),
    (RawClause = (RealH:-RawBody) -> true ; (RawClause=RealH, RawBody=true)),
    taxlogWrapper(RawBody,Explicit,Time,M,B,Ref,_IsProlog,_URL,_E),
    ((H=on(_,Time);Explicit==true)->TheH=on(RealH,Time);TheH=RealH),
    % ...now for the normal stuff:
    atomicSentence(TheH,VarNames,[],Vars1,Head),
    (B==true -> (LE=Head, VarsN=Vars1) ; (
        conditions(B,VarNames,Vars1,VarsN,Body),
        LE=if(Head,Body)
    )),
    length(VarsN,N),
    ( setof(Words,Var^member(v(Words,Var),VarsN),DistinctWords) -> true ; DistinctWords=[]),
    length(DistinctWords,Found),
    (Found==N->true ; throw("You need to use unambiguous variable names; avoid a trailing _ ?")).

bind_clause_vars([VN|VarNames],[Var|Vars]) :- !, arg(2,VN,Var), bind_clause_vars(VarNames,Vars).
bind_clause_vars([],[]).

% atomicSentence(Literal,ClauseVarNames,Vars,NewVars,LEterm)
% Vars is a list of the variables encountered so far, each a v(Words,Var)
% e.g. cgt_assets_net_value(Entity,Value) --> le_predicate([cgt,assets,net,value],[a([Entity]),a([Value])])

atomicSentence(at(Cond,KP),VarNames,V1,Vn,at(Conditions,Reference)) :- !,
    conditions(Cond,VarNames,V1,V2,Conditions),
    arguments([KP],VarNames,V2,Vn,[Reference]).
atomicSentence(on(Cond,Time),VarNames,V1,Vn,on(Conditions,Moment)) :- !,
    conditions(Cond,VarNames,V1,V2,Conditions),
    arguments([Time],VarNames,V2,Vn,[Moment]).
atomicSentence(true,_,V,V,true) :- !.
atomicSentence(false,_,V,V,false) :- !.
atomicSentence(Literal,VarNames,V1,Vn,le_template(Template,Arguments)) :-  Literal=..[F|Args], 
    dict([F|Args],_,Template), !, 
    arguments(Args,VarNames,V1,Vn,Arguments).
atomicSentence(Literal,VarNames,V1,Vn,le_predicate(Functor,Arguments)) :- Literal=..[F|Args],
    nameToWords(F,Functor), arguments(Args,VarNames,V1,Vn,Arguments).

% dict(LiteralElements, NamesAndTypes, Template)
% 
dict(['\'s_R&D_expense_credit_is', Project, ExtraDeduction, TaxCredit], 
                                  [project-projectid, extra-amount, credit-amount],
    [project, Project, '\'s', 'R&D', expense, credit, is, TaxCredit, plus, ExtraDeduction]).

arguments([],_,V,V,[]) :- !.
arguments([A1|An],VarNames,V1,Vn,[le_argument(Argument)|Arguments]) :- 
    argument(A1,VarNames,V1,V2,Argument), arguments(An,VarNames,V2,Vn,Arguments).

% argument(+A1,+VarNames,+V1,-Vn,-Argument)
argument(A1,VarNames,V1,Vn,Argument) :- var(A1), !,
    (find_var_name(A1,V1,Words) -> (
        Argument=the(Words), Vn=V1
        ) ; find_var_name(A1,VarNames,Name) -> (
            nameToWords(Name,Words),
            Argument=a(Words),
            Vn = [v(Words,A1)|V1]
        ) ; (
            Argument=le_some_thing, Vn=V1
    )).
argument(A1,_VarNames,V,V,A1) :-  atomic(A1),!.
argument(A1,VarNames,V1,Vn,NewA1) :- is_list(A1),!, arguments(A1,VarNames,V1,Vn,NewA1).
argument(A1,VarNames,V1,Vn,NewA1) :- compound(A1), !, compound_name_arguments(A1,F,Args),
    arguments(Args,VarNames,V1,Vn,NewArgs), compound_name_arguments(NewA1,F,NewArgs).
argument(A1,VarNames,V1,Vn,NewA1) :-  A1=..[F|Args], !, % terms in general; add case for isExpressionFunctor(F)?
    arguments(Args,VarNames,V1,Vn,NewArgs), NewA1=..[F|NewArgs].

conditions(V,_VarNames,V1,V1,Predicate) :- var(V), !,
    (find_var_name(V,V1,Words) -> Predicate=le_predicate(the(Words,unknown_arguments)) ; throw("Anonymous variable as body goal"-[])).
conditions(Cond,VarNames,V1,Vn,Condition) :- Cond=..[Connective,A,B], member(Connective,[and,or,must]), !,
    conditions(A,VarNames,V1,V2,NiceA), conditions(B,VarNames,V2,Vn,NiceB), 
    Condition=..[Connective,NiceA,NiceB].
conditions(then(if(C),else(T,E)),VarNames,V1,Vn,if_then_else(Condition,Then,Else)) :- !,
    conditions(C,VarNames,V1,V2,Condition), conditions(T,VarNames,V2,V3,Then), conditions(E,VarNames,V3,Vn,Else).
conditions(then(if(C),T),VarNames,V1,Vn,must(Condition,Then)) :- !,
    conditions(C,VarNames,V1,V2,Condition), conditions(T,VarNames,V2,Vn,Then).
%TODO: forall, setof, ->, other cases in i(...)
conditions(not(Cond),VarNames,V1,Vn,not(Condition)) :- !, conditions(Cond,VarNames,V1,Vn,Condition).
conditions((A,B),VarNames,V1,Vn,Condition) :- !, conditions(and(A,B),VarNames,V1,Vn,Condition).
conditions(';'(C->T,E),VarNames,V1,Vn,LE) :- !, conditions(then(if(C),else(T,E)),VarNames,V1,Vn,LE). % not quite the same meaning!
conditions((A;B),VarNames,V1,Vn,Condition) :- !, conditions(or(A,B),VarNames,V1,Vn,Condition).
conditions(\+ A,VarNames,V1,Vn,Condition) :- !, conditions(not(A),VarNames,V1,Vn,Condition).
conditions(call(G),VarNames,V1,Vn,Condition) :- !, conditions(G,VarNames,V1,Vn,Condition).
conditions(forall(Cond,Goal),VarNames,V1,Vn,for_all(Conditions, Goals)) :-  !, 
    conditions(Cond, VarNames, V1, V2, Conditions),
    conditions(Goal, VarNames, V2, Vn, Goals).
conditions(setof(X,Cond,Set),VarNames,V1,Vn,set_of(Index, Conditions, Collection)) :-  !, 
    arguments([X], VarNames, V1, V2, [Index]),
    conditions(Cond, VarNames, V2, V3, Conditions), 
    arguments([Set], VarNames, V3, Vn, [Collection]).
conditions(aggregate_all(Expr,Cond,Aggregate),VarNames,V1,Vn,aggregate_all(Op,Each,SuchThat,Result)) :- Expr=..[Op,Arg], !,
    arguments([Arg],VarNames,V1,V2,[Each]),
    conditions(Cond,VarNames,V2,V3,SuchThat),
    arguments([Aggregate],VarNames,V3,Vn,[Result]).
conditions(P,VarNames,V1,Vn,Predicate) :- 
    atomicSentence(P,VarNames,V1,Vn,Predicate).

% find_var_name(Var,VarNames,Name) VarNames is a list of Name=Var or v(Words,Var)
% finds the name for a (free, unbound) variable
find_var_name(V,[VN|_VarNames],Name) :- VN=..[_,Name,Var], V==Var, !.
find_var_name(V,[_|VarNames],Name) :- find_var_name(V,VarNames,Name).

%%%% Serving Logical English versions of the KB

:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/html_write)).

:- http_handler('/logicalEnglish', handle_le, []).  % parameters: either of kp or html (this uri encoded)
handle_le(Request) :-
    http_parameters(Request, [kp(Module_,[default('')]), html(ReadyHTML,[default('')])]),
    (ReadyHTML\='' -> ( 
        uri_encoded(path,ReadyHTML_,ReadyHTML),
        \[ReadyHTML_]=TheHTML, 
        assertion(Module_=='') 
        ) ; (
        atom_string(Module,Module_),
        loaded_kp(Module), le_kp_html(Module,TheHTML)
    )),
    reply_html_page([title("Logical English version")],[
        h2("Logical English"),
        \["<!-- "], % HTML comment
        "Your request: ~w"-[Request],
        \["-->"]
        |TheHTML
    ]).


:- if(current_module(swish)). %%%%% On SWISH:
:- multifile sandbox:safe_primitive/1.
sandbox:safe_primitive(logical_english:print_kp_le(_)).
sandbox:safe_primitive(logical_english:le(_)).
sandbox:safe_primitive(logical_english:le(_,_)).
:- endif.