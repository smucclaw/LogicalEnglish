:-module('https://www.ato.gov.au/general/capital-gains-tax/small-business-cgt-concessions/basic-conditions-for-the-small-business-cgt-concessions/affiliates/',[]).

% indicate future API entry point: predicate pattern, description
mainGoal(has_affiliated_with(_Entity,_Affiliate),"Determine if a given entity is affiliate of another (also given)").

example(test,[scenario([
    acts_in_accordance_with_directions_from(company,andrew), 
    is_a_trust(_) if false, 
    is_a_partnership(_) if false, 
    is_a_superannuation_fund(_) if false, 
    is_an_individual_or_a_company(_)
    ],true)]).

en("% affiliates.le
% http://demo.logicalcontracts.com:8082/p/cgt_affiliates.pl
%Knowledge page carefully crafted in Taxlog/Prolog from the legislation at
%https://www.ato.gov.au/general/capital-gains-tax/small-business-cgt-concessions/basic-conditions-for-the-small-business-cgt-concessions/affiliates/
%

the predicates are:
    a term must not be a variable,
    a term must be nonvar,
    an entity has affiliated with an affiliate at a date,
    a date is not before a second date,
    an affiliate is an individual or is a company,
    an affiliate is a trust,
    an affiliate is a partnership,
    an affiliate is a superannuation fund,
    an affiliate acts in accordance with directions from an entity,
    an affiliate acts in concert with an entity,
    an affiliate is affiliated per older legislation with an entity,
    an entity is a trust,
    an entity is a trust according to other legislation,
    an entity is a partnership,
    an entity is a partnership according to other legislation,
    an entity is a superannuation fund,
    an entity is a superannuation fund according to other legislation.

the knowledge base includes:
a term must not be a variable
    if the term must be nonvar.

an entity has affiliated with an affiliate at a date
    if the date is not before 20090101
    and the affiliate is an individual or is a company
    and it is not the case that
        the affiliate is a trust
    and it is not the case that
        the affiliate is a partnership
    and it is not the case that
        the affiliate is a superannuation fund
    and the affiliate acts in accordance with directions from the entity
        or  the affiliate acts in concert with the entity.

an entity has affiliated with an affiliate at a date
    if  the date is before 20090101
    and the entity must not be a variable
    and the affiliate must not be a variable
    and the affiliate is affiliated per older legislation with the entity.

% predefined
%an affiliate is an individual or is a company at a date
%    if myDB_entities:is_individual_or_company_on(the affiliate,the date).

an entity is a trust
    if the entity is a trust according to other legislation.

an entity is a partnership
    if the entity is a partnership according to other legislation.

an entity is a superannuation fund
    if the entity is a superannuation fund according to other legislation.
").

question( is_affiliated_per_older_legislation(Affiliate,Entity), "Is '~w' an affiliate of '~w' as per the older legislation" - [Affiliate,Entity]).



/** <examples>
?- query_with_facts(has_affiliated_with_at(andrew,company,'20200101'),test,Unknowns,Explanation,Result).
*/