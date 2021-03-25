# TaxKB
Prolog based generic knowledge base for tax regulations, including reasoner, editor and other tools

TBD: TOC, number sections


## Initial sample of examples

The following tax regulation fragments were indicated; original links and Tax-KB editor links below.

### LodgeIT

Provided via Andrew Noble email Nov 28, 2020, and earlier:
-  <https://www.ato.gov.au/general/capital-gains-tax/small-business-cgt-concessions/basic-conditions-for-the-small-business-cgt-concessions/>
	- Tax-KB [editor](http://demo.logicalcontracts.com:8082/p/cgt_concessions_basic_conditions_sb.pl)

- <https://www.ato.gov.au/general/capital-gains-tax/small-business-cgt-concessions/small-business-restructure-rollover/>
	- Bob's [GoogleDoc](https://docs.google.com/document/d/1fj8Cjp_FNKAIXvrUYD52Zpfgo6Ftqbypd8s36mC7CdA/edit?ts=5fc7e58b) analyzing it.
	- Tax-KB [editor](http://demo.logicalcontracts.com:8082/p/cgt_concessions_sb_restructure_rollover.pl)
- <https://www.ato.gov.au/general/capital-gains-tax/small-business-cgt-concessions/basic-conditions-for-the-small-business-cgt-concessions/maximum-net-asset-value-test/>
	- Bob's [GoogleDoc](https://docs.google.com/document/d/1wJl_JzZ7tkMMyia3eKdz1XlX6JBhYIcngJTESZQjz6E/edit?ts=5fd3aafc&skip_itp2_check=true)
	- Tax-KB [editor](http://demo.logicalcontracts.com:8082/p/cgt_maximum_net_asset_value.pl)
- <https://www.ato.gov.au/general/capital-gains-tax/small-business-cgt-concessions/basic-conditions-for-the-small-business-cgt-concessions/affiliates/>
	- Tax-KB [editor](http://demo.logicalcontracts.com:8082/p/cgt_affiliates.pl)
	- Further references (ignored in the first encoding): <https://pointonpartners.com.au/small-business-cgt-passing-the-threshold-tests/>

This was indicated (Dec 10 AN email) for later analysis: <https://www.taxtalks.com.au/small-business-participation-percentage/>


### AORA
_Some suggestions for simplification and more info in first and second Chris emails, Dec 2, 2020_

- <https://www.gov.uk/guidance/stamp-duty-reserve-tax-reliefs-and-exemptions>
	- Tax-KB [editor](http://demo.logicalcontracts.com:8082/p/stamp_duty_reserve_tax_reliefs.pl)
- <https://www.gov.uk/hmrc-internal-manuals/residence-domicile-and-remittance-basis/rdrm11040>
	- Tax-KB [editor](http://demo.logicalcontracts.com:8082/p/statutory_residence_test_guidance.pl)
	- Bob's [GoogleDoc](https://docs.google.com/document/d/1nzoGuzPKI375jxtxT38jCEYwuhuZvjSBSHmvxusW0Lg/edit?ts=5fc92d43#heading=h.pzozuu8bp8r0)
- <https://www.gov.uk/guidance/corporation-tax-research-and-development-rd-relief>
	- Tax-KB [editor](http://demo.logicalcontracts.com:8082/p/research_and_development_tax_reliefs.pl)

## TaxLog, the Tax-KB language

"**TaxLog**" is the "sugared Prolog" language used to encode the knowledge gleaned from regulatory textual sources into *knowledge pages*, forming a logical knowledge graph.

The text in regulatory sources comprises 3 types of fragments: 

- comments (to be effectively ignored); 
- rule ingredients (the main thing)
- examples

The term *knowledge page* denotes a Prolog module that encodes the knowledge in some web (or accessible via URL) page containing the regulatory text. This knowledge excludes instance (specific case) data, to be added in runtime. It is declared with a standard Prolog module declaration:

	:- module('http://myURLBase',[]).

This means that the knowldege page was constructed from the text at that URL. It must be the very first Prolog term in the file.

The logic language used is pure PROLOG (Horn clauses plus a few connectives, excluding cuts) but sugared with some additional operators in the clause bodies, towards readability and expressiveness:

  * ``if``, ``and``, ``or``, as alternatives to :- , ;
  * ``if...must/then..``  and ``if...then...else...``
  * Predicate ``on `` Moment
  * Predicate ``at`` KnowledgePageURL

The "deontic" ``if Condition (it) must (be true that) Obligation`` in a clause body is simply mapped into ``Condition and Obligation or not Condition``. The term "deontic" is being stretched here, cf. for example this explanation on [deonthic vs. alethic](https://www.brsolutions.com/the-two-fundamental-kinds-of-business-rules-where-they-come-from-and-why-they-are-what-they-are/).

The ``on `` notation allows specification of a timestamp to the predicate, effectively adding it an extra argument. All predicates are "fluents", e.g. considered to have a timestamp, which may be implicit - in which case the predicate holds true "for all time".

The ``P at KP`` metapredicate in a rule body refers a separate source of knowledge:

	someRuleHead if ... and P at "http://someURL" and ...

This allows reference of "external knowledge", e.g. predicates defined in other knowledge pages or external databases. The term *knowledge page* means: the knowledge base fragment encoding the knowledge in web page ``KP``. The truth of ``P`` will therefore be evaluated in KP. This is similar to Prolog's call ```KP:P```, except that ```at``` abstracts from file names and uses a specific (and SWISH-aware) module loading mechanism.

Each predicate P may be:

	* true
	* false
	* unknown

Unknown values can potentially fuel a user dialog. For example, if ``has_aggregated_turnover(tfn1,X) at WWW`` is evaluated as unknown (because the system has no access to the turnover value in order to bind variable X), this could dictate the user question: 

	What is the aggregated turnover of entity tfn1 ? Refer to WWW for more info

Fully bound literals originate yes/no questions. These questions, generated in reaction to a query to the knowledge base, can provide the base for a chatbot. 

### Other constructs

In addition to the above features supporting knowledge representation, there are a few more:

	mainGoal(PredicateTemplate, Description).

Each such fact identifies a predicate to be exposed via the (REST) API; however at this point the REST API provides access to any predicate in a knowledge page, so this should be seen as more of a documentation feature.

	example(Title,StatesAndAssertions).
	
This represents a test case, an example of the application of the knowledge rules in the module, providing it with "instance" data specific to some taxpayer, asset, etc. Regulatory (guidance) text sometimes provides them, to lighten their explanations. ``StatesAndAssertions``is an ordered list of ``scenario(Facts, Postcondition)``. Facts is a list of predicate facts (Fact or Fact on Time), with some variants:

 * a prefix ``- `` denotes deletion; the rest of the term must be a fact (nbot a rule). 
 * a prefix ``++`` denotes extension: the fact or rule is added to existing facts and rules (instead of redefining them if no prefix is used); if a single + is used for a predicate, all other example facts and rules for that predicate are also additions (not redefinitions)
 * Head if Body adds a clause; if Body is ``false``, the rule effectively asserts not(Head) as per Negation As Failure
 * Other terms are regarded as facts
 * Head at KP adds the fact (or rule) to the module KP
 

To try an example, for each all facts in the StatesAndAssertions sequence are added/deleted, in sequence, and the PostCondition (assertion) is evaluated at the end.

These example facts are also test cases: all assertions must be true.

**User functions** can be defined locally in a module with the ```function/2``` meta predicate:

	function(project(), Result) if theProject(Result).

This is meant mostly as a convenience/readability feature, e.g. being able to write ```is_exempt( project() )``` instead of ```theProject(Project) and is_exempt(Project)```.

Unknown predicate literals are in fact the "juice" for questions to a human, which can be rendered with more detail if available, via the following optional annotation facts:

	question(Literal,QuestionTerm)		a yes/no question
	question(Literal, QuestionTerm, Answer)	elicit some answer content from the user; the Answer and Literal terms need to share some variable

QuestionTerm can be a string, or a ```FormatString-ArgumentsList``` term, to allow for binding the question string with values, using the [format/2](https://www.swi-prolog.org/pldoc/doc_for?object=format/2) syntax.

### Interfacing to external systems

Access to data in external DBs or other services is done via (*unrestricted, possibly with cuts and all*) Prolog code. To have a predicate called directly (instead of it being interpreted like the rest by the Taxlog interpreter), it needs to be declared with a single ```Predicate on Time because Explanation``` clause "stub", allowing the external code both to consider time and to contribute its own bit of explanations; for example:

	is_sme(E) if is_small_business(E).
	
	is_small_business(E) on T because SomeExplanation :-
		call_my_DB(E,T,SomeExplanation).

The ```is_sme``` Taxlog predicate (which is interpreted) calls the ```call_my_DB ``` Prolog predicate directly, sharing time and getting an explanation for the DB result. The provided SomeExplanation term is regarded as an informal predicate literal in the overall explanation tree.

(TODO: fix this hack) SomeExplanation MUST be textually different from '[]'.

## Towards Logical English
**"Logical English"** (LE) is an attempt at a design "sweet spot" in the continuum from natural to constrained to formal languages - closer to the latter, but retaining most of the legibility of clear, natural English. For more about it see references at the top of Bob Kowalski's [home page](https://www.doc.ic.ac.uk/~rak/).

Tax-KB includes a preliminary **Logical English generator**, based on introspection of the Taxlog/Prolog clauses and its variable names, dispensing, for the moment, any additional linguistic information. This is intended as a first step towards a future full blown LE module, to include LE parsing; by exposing prospect users to the present LE representantions these can be validated, commented upon, and a precise specification can be established for the future parser. 

From a practical perspective, the LE generator gives an incentive to Taxlog coders to write more readable code, and provides material to share via Word documents etc. with "lawyer-like" people.

### Direct access to Logical English rendering

To see it at work, take the module name **KP** of any knowledge page (*the argument in the :-module(KP) directive at its top*), and open the URL "http://demo.logicalcontracts.com:8082/logicalEnglish?kp=**KP**". 

For example, for the KP regarding affiliates in Australian CGT regulations, open:

 > <http://demo.logicalcontracts.com:8082/logicalEnglish?kp=https://www.ato.gov.au/general/capital-gains-tax/small-business-cgt-concessions/basic-conditions-for-the-small-business-cgt-concessions/affiliates/>

Predicates remote to that page have *other legislation* links, which lead to either other "Logical English" pages (if a knowledge page already exists for it) or to the original legislation website. There is always also a link to the Taxlog (executable) representation, in the Tax-KB editor.

The resulting web page can be copied and pasted into Microsoft Word or similar tools.

### To improve the Logical English representation
LE is rendered dynamically from a current knowledge page:

- Open a knowledge page, for example <http://demo.logicalcontracts.com:8082/p/cgt_affiliates.pl>
- Run the goal le(Link). 
- Click the "Show Logical English" button in the Link variable result

If you change your Taxlog rules *and* **save** them, using the File/Save...  menu in the SWISH window, you can then Run ```le(Link)``` again and you'll get access to the updated LE representation. In the above example you might want to try renaming "affiliate" to either "hasAffiliate" or "has_affiliate".

The LE generator has an option to omit indefinite articles, which may arguably lead to more natural sentences: ```le([no_indefinites], Link)```.

### Logical English style checking
You may have noticed red curly lines under some sentences, with a tip appearing on hovering the mouse. As "atomic sentences" are generated for each predicate and its arguments, Tax-KB checks (using the SpaCy parser) that they are rooted in a verb. 

Notice that SpaCy, being a neural parser embedding a model trained from many real English sentences, uses the whole sentence to tag words as verbs, nouns etc. Arguably, making SpaCy "happier" (*e.g. making the curly red lines disappear by renaming predicate and argument names*) should reflect into more natural sentences.

### Technical details
The Logical English generator is based on cascading two main predicates:

- [le_clause(Head,Module,Ref,LogicalEnglish)](https://github.com/mcalejo/TaxKB/blob/main/logical_english.pl#L264), which introspects a single Prolog clause and returns an intermediate LE representation
- [le_kp_html(Module,Options,TermrisedHTML)](https://github.com/mcalejo/TaxKB/blob/main/logical_english.pl#L72), which processes the above into HTML. 

The latter includes the (*potentially more expensive*) step of calling the Spacy parser REST service to parse the generated atomic sentences, source code specifically [here](https://github.com/mcalejo/TaxKB/blob/main/logical_english.pl#L225).

Standard Prolog clause introspection is used, plus some SWI-Prolog extensions for variable names, combined with CamelCase and under_score [detection](https://github.com/mcalejo/TaxKB/blob/main/drafter.pl#L79)

## Predicate and URL reference

### Language processing
- ```parseAndSee(Text,SentenceIndex,Tokens,HierplaneTree)``` Useful to explore syntactic and lexical aspects of text
- ```test_draft(Text,DraftedCode)``` given a string with English, try to generate simple Prolog predicate templates for verb phrases

### Perspective on existing (encoded) Knowledge Pages
*Note: in the following predicates, leaving KP unbound will show not one, but all knowledge pages*
- ```knowledgePagesGraph(KP,Graph)```
	- TIP: hover the top left corner, Download GraphViz Graph, Save/Print to PDF
- ```print_kp_predicates(KP)```
- ```printAllPredicateWords(KP)```
- ```predicateWords(KP,Pred,PredWords)```, ```uniquePredicateSentences(KP,S)```, ```uniqueArgSentences(KP,S)```
- REST???
- ```le(Link)``` generate Logical English web page and bind Link to a navigation button
	- ```le([no_indefinites],Link)``` same but omitting a/an articles
- REST API GET for preliminary Logical Engish
	- http://demo.logicalcontracts.com:8082/logicalEnglish?kp=**KP**"

### Querying
- ```query_with_facts(Goal,FactsSource,Unknowns,Explanation,Result)```
	- Goal is of the form ```G at KP```
	- If simply G: KP is assumed to be the module in the current editor
	- If time is relevant use ```G’ on Datetime```
	- FactsSource is either a list of facts/rules or an example name in KP
	- Unknowns are predicate calls assumed true and supporting the answer (we want it to be [])
	- Explanation is a justification of the answer, a tree represented in a large Prolog term which the Tax-KB SWISH renderer displays as an indented list, including navigation links etc.
	- Result is either of true/unknown/false
- REST API GET
	xxxxx
- ```render_questions(Unknown,Questions)``` uses question(…) fact annotations to obtain more readable "questions"

## Installation and deployment

### Architecture
A Tax-KB instance comprises two Docker containers and a copy of this git repository:
- SpacY standalone container, built from this [Dockerfile](https://github.com/mcalejo/TaxKB/blob/main/spacy/docker/Dockerfile) and accessible on port 8080
- SWI-Prolog with (*slightly tweaked, but independent from Tax-KB*) SWISH container, web server included, built from another [Dockerfile](https://github.com/mcalejo/TaxKB/blob/main/swish/dockerfile)
	- This Docker container is launched (*cf. comments at the top of the Dockerfile*) with two host volumes mounted: a SWISH work data directory, and a copy of [this](https://github.com/mcalejo/TaxKB) repository; in addition, several environment variables are passed, referred next

The SWI-Prolog+SWISH Docker container does not contain any Tax-KB specific code. It is "customised" for Tax-KB via parameters passed on startup, as environment variables:
* -e LOAD='/TaxKB/swish/user_module_for_swish.pl' : indicates the startup Prolog file, which loads everything
* -e SPACY_HOST=demo.logicalcontracts.com:8080 : the address of the SpaCy REST service for parsing
* -e SUDO=false: if true (only for development!), this provides a sudo(AnyGoal) Prolog "backdoor meta predicate", shortcircuiting SWISH's safe sandbox restrictions
* -e LOAD_KB=true: whether the SWISH internal storage is loaded at startup with all knowledge pages in the kb/ directory, overwriting any existing ones


### Where is the knowledge: SWISH storage vs. file system
A word about **SWISH storage**, to understand the need for the last parameter above (LOAD_KB). 

When a user saves a Prolog file with the SWISH web editor, it does not go straightly into the server file system; instead, it is stored in a SWISH internal storage area (persisting in the /data volume mounted in the Docker container); this provides limited versioning, tagging and related services, nicknamed internally as "[gitty storage](https://github.com/SWI-Prolog/swish/blob/master/lib/storage.pl#L83)". Such files can be opened in the SWISH syntax-aware web editor via the URL SERVER/p/filename.pl, and are listed in SWISH's 

But for the sake of easier versioning, integration with the Tax-KB code base etc. the knowledge pages (for the initial 6 samples) are maintained in [kb/](https://github.com/mcalejo/TaxKB/tree/main/kb), not on SWISH storage. So during development, it's convenient that on startup the knowledge pages are copied into SWISH storage, so they appear in SWISH's "file" browser and can be opened easily. Hence the LOAD_KB parameter.

For a deployed system, it may be better to use LOAD_KB=false, so that on restart the Tax-KB preserves the latest user changes to knowldege pages. 

There are two Prolog predicates for copying all knowledge pages between SWISH storage and the kb/ directory:
- load_gitty_files: copies from kb/ into SWISH storage
- save_gitty_files: copies from SWISH storage into the kb/ directory

The latter allows git tracking of server changes, a posteriori. 

When deploying a real system this needs to be tuned, possibly using a specific git branch (e.g. "deployed-version") for the server kb/, so that user changes can later be merged safely into master, after some quality control/review process TBD.

## Implementational aspects

### Rendering
SWISH includes a powerful Prolog term renderer mechanism, allowing the generation of arbitrary HTML (including possibly the reeling in of Javascript components). Tax-KB includes several specific renderers, for:
- [Parse trees](https://github.com/mcalejo/TaxKB/blob/main/spacy/hierplane_renderer.pl); this embeds AllenAI's powerful [hierplane](https://allenai.github.io/hierplane)
	- Token lists are rendered with SWISH's standard [table renderer](http://demo.logicalcontracts.com:8082/example/render_table.swinb)
- Logical English [navigation links](https://github.com/mcalejo/TaxKB/blob/main/swish/le_link_renderer.pl), effectively embedding a hidden form containing the generated HTML with the LE representation
	- this is articulated with the le(..) predicate; for direct URL access to LE this renderer is not used
- [Explanation trees](https://github.com/mcalejo/TaxKB/blob/main/swish/explanation_renderer.pl)
- [Unknowns lists](https://github.com/mcalejo/TaxKB/blob/main/swish/unknowns_renderer.pl)
### Editor
