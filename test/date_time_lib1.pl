:- use_module(library(date_time)).
:- use_module(library(clpfd)).

is_duration_before(T0, Duration, T1) :-
  maplist(relative_to_absolute_date, [T0, T1], [Date0, Date1]),
  is_duration_before_dates(Date0, Duration, Date1),
  maplist(absolute_to_relative_date, [Date0, Date1], [T0, T1]).

is_duration_before_dates(Date0, Duration, Date1) :-
  Date0 = Day0 / Month0 / Year0,
  Date1 = Day1 / Month1 / Year1,
  maplist(is_valid_date, [Date0, Date1]),
  lex_chain([[Year0, Month0, Day0], [Year1, Month1, Day1]]),
  labeling([max(Year0), max(Year1)], [Year0, Year1, Month0, Month1, Day0, Day1]),
  date_interval(date(Year1, Month1, Day1), date(Year0, Month0, Day0), Duration).

relative_to_absolute_date(Relative_date, Day / Month / Year) :-
  member(Relative_date, [yesterday, today, tomorrow]),
  date_get(Relative_date, date(Year, Month, Day)).

relative_to_absolute_date(Relative_date, _ / _ / _) :-
  maplist(dif(Relative_date), [yesterday, today, tomorrow]).

absolute_to_relative_date(Day / Month / Year, Relative_date) :-
  member(Relative_date, [yesterday, today, tomorrow]),
  date_get(Relative_date, date(Year, Month, Day)).

absolute_to_relative_date(Day / Month / Year, Relative_date) :-
  maplist(integer, [Year, Month, Day]),
  maplist(dif(Relative_date), [yesterday, today, tomorrow]).
  % date_time_stamp(date(Year, Month, Day, 0, 0, 0, _, _, _), Timestamp).

is_valid_date(Day / Month / Year) :-
  Year in 1..3000,
  Month in 1..12,
  Day in 1..31,
  (Month in 4 \/ 6 \/ 9 \/ 11) #==> Day #=< 30,
  Month #= 2 #==> Day #=< 29,
  (Month #= 2 #/\ Day #= 29) #<==> ((Year mod 400 #= 0) #\/ (Year mod 4 #= 0 #/\ Year mod 100 #\= 0)).