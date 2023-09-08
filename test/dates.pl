:- use_module(library(date_time)).
:- use_module(library(clpfd)).

is_duration_before(T0, Duration, T1) :-
  member(T0, [yesterday, today, tomorrow]),
  member(T1, [yesterday, today, tomorrow]),
  date_get(T0, Date0),
  date_get(T1, Date1),
  date_interval(Date1, Date0, Duration).

is_duration_before(T0, Duration, T1) :-
  member(T0, [yesterday, today, tomorrow]),
  dif(T1, yesterday), dif(T1, today), dif(T1, tomorrow),
  date_get(T0, Date0),
  is_duration_before_dates(Date0, Duration, Date1),
  my_date_time_stamp(Date1, T1).

is_duration_before(T0, Duration, T1) :-
  dif(T0, yesterday), dif(T0, today), dif(T0, tomorrow),
  member(T1, [yesterday, today, tomorrow]),
  date_get(T1, Date1),
  is_duration_before_dates(Date0, Duration, Date1),
  my_date_time_stamp(Date0, T0).

is_duration_before_dates(Date0, Duration, Date1) :-
  Date0 =.. [date, Year0, Month0, Day0],
  Date1 =.. [date, Year1, Month1, Day1],
  maplist(my_is_date, [Date0, Date1]),
  lexical_leq(Date0, Date1),
  labeling([max(Year0), max(Year1)], [Year0, Year1, Month0, Month1, Day0, Day1]),
  date_interval(Date1, Date0, Duration).

my_date_time_stamp(Date, X) :-
  member(X, [yesterday, today, tomorrow]),
  date_get(X, Date).

my_date_time_stamp(date(Year, Month, Day), Timestamp) :-
  date_time_stamp(date(Year, Month, Day, 0, 0, 0, _, _, _), Timestamp).

my_is_date(date(Year, Month, Day)) :-
  Year in 1..3000,
  Month in 1..12,
  Day in 1..31,
  (Month #= 4 #\/ Month #= 6 #\/ Month #=9 #\/ Month #= 11) #==> Day #=< 30,
  Month #= 2 #==> Day #=< 29,
  (Month #= 2 #/\ Day #= 29) #<==> ((Year mod 400 #= 0) #\/ (Year mod 4 #= 0 #/\ Year mod 100 #\= 0)).

lexical_leq(date(Year0, Month0, Day0), date(Year1, Month1, Day1)) :-
  Year0 #=< Year1,
  Year0 #= Year1 #==> Month0 #=< Month1,
  Month0 #= Month1 #==> Day0 #=< Day1.