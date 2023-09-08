:- use_module(library(date_time)).
:- use_module(library(clpfd)).

is_duration_before(T0, Duration, T1) :-
  maplist(timestamp_to_date, [T0, T1], [Date0, Date1]),
  is_duration_before_dates(Date0, Duration, Date1),
  maplist(date_to_timestamp, [Date0, Date1], [T0, T1]).

is_duration_before_dates(Date0, Duration, Date1) :-
  Date0 = date(Year0, Month0, Day0),
  Date1 = date(Year1, Month1, Day1),
  maplist(is_valid_date, [Date0, Date1]),
  lex_chain([[Year0, Month0, Day0], [Year1, Month1, Day1]]),
  labeling([max(Year0), max(Year1)], [Year0, Year1, Month0, Month1, Day0, Day1]),
  date_interval(Date1, Date0, Duration).

% date_difference(date(Y1,M1,D1), date(Y2,M2,D2), [years(Y), months(M), days(D)]) :-
%   my_is_date(date(Y1, M1, D1)),
%   my_is_date(date(Y2, M2, D2)),
%   my_is_date(date(Y1, M1a, Dprev)),
%   (D2 #> D1 #==>
%     (((M1 in 4 \/ 6 \/ 9 \/ 11 #/\ D1 + 1 #> 31) #\/
%       (M1 #= 2 #/\ D1 + 1#> 29) #\/
%       (M1 #= 2 #/\ D1 #= 29 #/\ #\ ((Y1 mod 400 #= 0) #\/ (Y1 mod 4 #= 0 #/\ Y1 mod 100 #\= 0))))
%       #==>
%         M1a #= M1 #/\
%         D1a #= D2
%         #\/
%         M1a #= M1 - 1 #/\
%         date_month_days(M1a,Y1,Dprev) #/\
%         D1a #= D1 + Dprev)
%     #\/
%     D1a #= D1 #/\
%     M1a #= M1 ) #/\
%   (M2 #> M1a #==>
%     M1b #= M1a + 12 #/\
%     Y1b #= Y1 - 1
%     #\/
%     M1b #= M1a #/\
%     Y1b #= Y1 ) #/\
%   Y #= Y1b - Y2 #/\
%   M #= M1b - M2 #/\
%   D #= D1a - D2.

timestamp_to_date(Timestamp, Date) :-
  member(Timestamp, [yesterday, today, tomorrow]),
  date_get(Timestamp, Date).

timestamp_to_date(Timestamp, date(_, _, _)) :-
  maplist(dif(Timestamp), [yesterday, today, tomorrow]).

date_to_timestamp(Date, Timestamp) :-
  member(Timestamp, [yesterday, today, tomorrow]),
  date_get(Timestamp, Date).

date_to_timestamp(date(Year, Month, Day), Timestamp) :-
  maplist(integer, [Year, Month, Day]),
  maplist(dif(Timestamp), [yesterday, today, tomorrow]),
  date_time_stamp(date(Year, Month, Day, 0, 0, 0, _, _, _), Timestamp).

is_valid_date(date(Year, Month, Day)) :-
  Year in 1..3000,
  Month in 1..12,
  Day in 1..31,
  (Month in 4 \/ 6 \/ 9 \/ 11) #==> Day #=< 30,
  Month #= 2 #==> Day #=< 29,
  (Month #= 2 #/\ Day #= 29) #<==> ((Year mod 400 #= 0) #\/ (Year mod 4 #= 0 #/\ Year mod 100 #\= 0)).