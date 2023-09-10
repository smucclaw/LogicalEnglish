:- use_module(library(date_time)).
:- use_module(library(clpfd)).

:- use_module(library(janus)).
:- py_add_lib_dir(.).

% is_duration_before(T0, Duration, T1) :-
%   maplist(relative_to_absolute_date, [T0, T1], [Date0, Date1]),
%   is_duration_before_dates(Date0, Duration, Date1),
%   maplist(absolute_to_relative_date, [Date0, Date1], [T0, T1]).

is_duration_before(Date, Duration, Date) :-
  member(D, [days, weeks, months, years]),
  Duration =.. [D, 0],
  ( Date = today
    ; 
    % z3_is_valid_date(Date)
  (
      is_valid_date(Date),
      Date =.. [date | Year_month_day],
      label(Year_month_day)
    )
  ).

% is_duration_before(today, Duration, Date) :-
%   date_get(today, Today),
%   is_duration_before_dates(Today, Duration, Date).

% is_duration_before(Date, Duration, today) :-
%   date_get(today, Today),
%   is_duration_before_dates(Date, Duration, Today).

is_duration_before(Date0, Duration, Date1) :-
  maplist(to_date, [Date0, Date1], [Date0_, Date1_]),
  is_duration_before_dates(Date0_, Duration, Date1_).

to_date(Date, Date_) :-
  member(Date, [yesterday, today, tomorrow]),
  date_get(Date, Date_).

to_date(Date, Date) :- is_valid_date(Date).

is_duration_before_dates(Date0, Duration, Date1) :-
  Date0 = date(Year0, Month0, Day0),
  Date1 = date(Year1, Month1, Day1),

  Duration =.. [Duration_f, Duration_num],
  member(Duration_f, [days, weeks, months, years]),
  Duration_num in 0..sup,

  maplist(is_valid_date, [Date0, Date1]),
  lex_chain([[Year0, Month0, Day0], [Year1, Month1, Day1]]),

  ( maplist(integer, [Duration_num, Day0, Month0, Year0]), !,
    date_add(Date0, Duration, Date1)
    ;
    maplist(integer, [Duration_num, Day1, Month1, Year1]), !,
    Duration_neg =.. [Duration_f, -Duration_num],
    date_add(Date1, Duration_neg, Date0)
    ;
    label([Year0, Year1, Month0, Month1, Day0, Day1]),
    % z3_is_valid_date_pair(Date0, Date1),
    writeln([Date0, Date1]),
    date_interval(Date1, Date0, Duration)
  ).

is_valid_date(date(Year, Month, Day)) :-
  Year in 1900..2200,
  Month in 1..12,
  Day in 1..31,
  (Month in 4 \/ 6 \/ 9 \/ 11) #==> Day #=< 30,
  Month #= 2 #==> Day #=< 29,
  (Month #= 2 #/\ Day #= 29) #==> ((Year mod 400 #= 0) #\/ (Year mod 4 #= 0 #/\ Year mod 100 #\= 0)).

% relative_to_absolute_date(Relative_date, Day / Month / Year) :-
%   member(Relative_date, [yesterday, today, tomorrow]),
%   date_get(Relative_date, date(Year, Month, Day)).

% relative_to_absolute_date(Relative_date, _ / _ / _) :-
%   maplist(dif(Relative_date), [yesterday, today, tomorrow]).

% absolute_to_relative_date(Day / Month / Year, Relative_date) :-
%   member(Relative_date, [yesterday, today, tomorrow]),
%   date_get(Relative_date, date(Year, Month, Day)).

% absolute_to_relative_date(Day / Month / Year, Relative_date) :-
%   maplist(integer, [Year, Month, Day]),
%   maplist(dif(Relative_date), [yesterday, today, tomorrow]).
%   % date_time_stamp(date(Year, Month, Day, 0, 0, 0, _, _, _), Timestamp).

z3_is_valid_date(date(Year, Month, Day)) :-
  (integer(Day) -> Day_in = Day ; Day_in = day),
  (integer(Month) -> Month_in = Month ; Month_in = month),
  (integer(Year) -> Year_in = Year ; Year_in = year),
  py_iter(date_time_lib:is_valid_date(Day_in, Month_in, Year_in), [Day, Month, Year]).

z3_is_valid_date_pair(date(Year0, Month0, Day0), date(Year1, Month1, Day1)) :-
  (integer(Day0) -> Day0_in = Day0 ; Day0_in = day),
  (integer(Month0) -> Month0_in = Month0 ; Month0_in = month),
  (integer(Year0) -> Year0_in = Year0 ; Year0_in = year),
  (integer(Day1) -> Day1_in = Day1 ; Day1_in = day),
  (integer(Month1) -> Month1_in = Month1 ; Month1_in = month),
  (integer(Year1) -> Year1_in = Year1 ; Year1_in = year),
  py_iter(
    date_time_lib:is_valid_date_pair(Day0_in, Month0_in, Year0_in, Day1_in, Month1_in, Year1_in),
    [Day0, Month0, Year0, Day1, Month1, Year1]
  ).