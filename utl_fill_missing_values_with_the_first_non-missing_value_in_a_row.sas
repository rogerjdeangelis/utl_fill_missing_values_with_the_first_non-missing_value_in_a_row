Fill missing values with the first non-missing value in a row

WPS/SAS same results;

https://goo.gl/gs3VBv
https://communities.sas.com/t5/Base-SAS-Programming/Fill-missing-values-with-the-first-non-missing-value-in-a-row/m-p/429346

* very slight non important change (brackets '[]' instead of '()' to avoid
  accidental function;
novinosrin profile
https://communities.sas.com/t5/user/viewprofilepage/user-id/138205

The best algorithm? (Soren)

data have;
input t1-t5;
cards4;
. 1 2 3 4
. . 2 3 4
0 1 2 3 4
;;;;
run;quit;

data want_x;
set have;
array t(*) t:;
 _N_=nmiss(of t(*));
if 0<_N_<dim(t) then
call pokelong (repeat (put (t(_N_+1),rb8.), _N_), addrlong(t1));
run;quit;
INPUT

 WORK.HAVE total obs=4

   A    B    C    D    E

   .    .    .    .    .
   .    1    2    3    4
   .    .    2    3    4
   0    1    2    3    4

RULES  ( I would like to fill the missing values with the first non-missing value in each row.)

   A    B    C    D    E

   .    .    .    .    .
   1    1    2    3    4   A set to 1  because first non-iss is 1
   2    2    2    3    4   A & B set to 2 because first non-iss is 2
   0    1    2    3    4

PROCESS

  data want;
   set have;
   array t(*) A--E;
   do _n_=1 to dim(t);
     if t[_n_]=. then t[_n_]=coalesce(of t[*]);
   end;
  run;quit;

OUTPUT

 WORK.WANT total obs=4

   A    B    C    D    E

   .    .    .    .    .
   1    1    2    3    4
   2    2    2    3    4
   0    1    2    3    4

*                _              _       _
 _ __ ___   __ _| | _____    __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \  / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/ | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|  \__,_|\__,_|\__\__,_|
;

data have;
input a b c d e;
cards4;
. . . . .
. 1 2 3 4
. . 2 3 4
0 1 2 3 4
;;;;
run;quit;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __
/ __|/ _ \| | | | | __| |/ _ \| '_ \
\__ \ (_) | | |_| | |_| | (_) | | | |
|___/\___/|_|\__,_|\__|_|\___/|_| |_|
;

%utl_submit_wps64('
libname wrk sas7bdat "%sysfunc(pathname(work))";
data wrk.want;
 set wrk.have;
 array t(*) A--E;
 do _n_=1 to dim(t);
   if t[_n_]=. then t[_n_]=coalesce(of t[*]);
 end;
run;quit;
');
*            _
 _ __   __ _| |_
| '_ \ / _` | __|
| | | | (_| | |_
|_| |_|\__,_|\__|

;

SAS-L update

Nat Wooding <nathani@VERIZON.NET>


  data want;
   set have;
   array t(*) A--E;
   do _n_=1 to dim(t);
     if t[_n_]=. then t[_n_]=coalesce(of t[*]);
   end;
  run;

will require the implementation of the function every time a missing value is encountered.
If there are lots of obs with multiple missing values,
I would suggest moving the function call outside of the loop;


  data want;
   set have;
   array t(*) A--E;
   First_N_M = coalesce(of t[*]);
Drop First_N_M ;
   do _n_=1 to dim(t);
     if t[_n_]=. then t[_n_]= First_N_M ;
   end;
  run;

Nat

*
 ___  ___  _ __ ___ _ __
/ __|/ _ \| '__/ _ \ '_ \
\__ \ (_) | | |  __/ | | |
|___/\___/|_|  \___|_| |_|

;

Søren Lassen <000002b7c5cf1459-dmarc-request@listserv.uga.edu>
8:52 AM (6 hours ago)

 to SAS-L
Paul,
I tried exploding the input dataset to 4 million records;
the various programs then took about a second to run on my laptop.

Of the suggestions I tried, Nat's was about the fastest.
I also tried the simplest possible dummy version:
data want;
  set have;
  array t a--e;
  do _N_=dim(t)-1 to 1 by -1;
    if missing(t(_N_)) then t(_N_)=t(_N_+1);
    end;
run;
That, again, ran in about the same time as
Nat's suggestion (about .8 CPU seconds),
while your suggestion and the one with repeated calls of
COALESCE were slower (about 1 CPU second).

So I think I prefer my own "dummy" version, which will also
work with character arrays and non-contiguous arrays.

Regards,
Søren
Paul Dorfman via listserv.uga.edu
2:37 PM (50 minutes ago)

 to SAS-L
Søren,

*                  _
 _ __   __ _ _   _| |
| '_ \ / _` | | | | |
| |_) | (_| | |_| | |
| .__/ \__,_|\__,_|_|
|_|
;


Fair enough, but by "big" I mean not the number of observations but the number of array elements.
If you try as below, it will likely flip. For the purity of the experiment, replace want_p and
want_s with _null_ to de-factor the write time. Also, with the APP method, there's room for
improvement at the expense of conciseness. E.g., addrlong(t1) and the pokelong plugs can
be pre-computed at _n_=1 and retained, etc. Ain't it fun ;).

Best
Paul

data have ;
  array t t1-t999 ;
  do _iorc_ = 1 to 1e5 ;
    _n_ = ceil (ranuni(1) * dim(t)) ;
    do over t ;
      t = ifN (_i_ < _n_, . , ceil (ranuni(2) * 9)) ;
    end ;
    if ranuni(3) < .001 then call missing (of t:) ;
    output ;
  end ;
run ;

data want_p ;
  set have ;
  array t t: ;
  do over t ;
    if N(t) then leave ;
  end ;
  if 1 < _i_ <= dim(t) then call pokelong (repeat (put (t,rb8.), _i_-2), addrlong(t1)) ;
run ;

data want_s ;
  set have;
  array t t: ;
  do _N_=dim(t)-1 to 1 by -1;
    if missing(t(_N_)) then t(_N_)=t(_N_+1);
    end;
run;

   *
     ___  ___  _ __ ___ _ __
    / __|/ _ \| '__/ _ \ '_ \
    \__ \ (_) | | |  __/ | | |
    |___/\___/|_|  \___|_| |_|

    ;

aul,
You are right, my primitive solution (which on the other hand has the advantage of 
being easier to understand and maintain, and more general) is quite a 
lot slower than your suggested solutions.

But the fastest way to find the left-most non-missing seems to be NMISS:
data want_x;
  set have;
  array t(*) t:;
  _N_=nmiss(of t(*));
  if 0<_N_<dim(t) then
    call pokelong (repeat (put (t(_N_+1),rb8.), _N_), addrlong(t1));
run;

This is the fastest solution I have yet tried with your data. And it also works 
with special missing values, but of course not with non-contiguous arrays or character arrays.

I tested, and there seemed to be a performance gain by precalculating the 
addrlong result, but not very much.

Regards,
Søren

*_____     _          _   _____
|  ___| __(_) ___  __| | | ____|__ _  __ _
| |_ | '__| |/ _ \/ _` | |  _| / _` |/ _` |
|  _|| |  | |  __/ (_| | | |__| (_| | (_| |
|_|  |_|  |_|\___|\__,_| |_____\__, |\__, |
                               |___/ |___/
;

Fried Egg via listserv.uga.edu
6:56 PM (14 hours ago)

 to SAS-L
Here is another method, for the hell of it…  It is the fastest generalized
approach of those I’ve noticed be mentioned, so far.  I included NMISS,
which is still the overall fastest approach to the direct problem.  The C
code implemented in the PROTO Procedure essentially performs the identical
behavior of the iterative do-loop in SAS data step.  It looks, sequentially,
at each item in the array, checks if it is “missing” and moves on, as
necessary until a non-missing value is encountered.  ZMISS is a built-in
function provided by the PROTO Procedure which checks for the SAS “missing”
value.

My run;quitt seemed to terminate 'proc proto' cleanly


proc proto packet=work.func.proto;

   double c_firstNMISS(double * p);
   externc c_firstNMISS;
   double c_firstNMISS (double * p)
   {
    int i;
    for (i = 0; ZMISS(p[i]); i++) {}
    return p[i];
   }
   externcend;
run;quit;

proc fcmp inlib=work.func outlib=work.func.fcmp;
   function firstNMISS(dp[*]);
   return (c_firstNMISS(dp));
   endsub;
   array x[7] (. . . . . 1.01 1.02);
   z=firstNMISS(x);
   put z=;
run;quit;

options cmplib=(work.func);
data _null_ ;
  array t [999] _temporary_ (499*. 500*1);
  do i=1 to 1e6;
      z=firstNMISS(t);
  end;
run ;quit;

https://imgur.com/AZ2Sf12 (includes code used to perform testing and
produce above graphic)
Comparisons significant at the 0.05 level are indicated by ***.
method
Comparison
Difference
Between
Means
95% Confidence Limits
do_loop - nmiss
0.161
-14.667
14.988
do_loop - compare
0.231
-14.597
15.058
do_loop - c_loop
1.114
-13.713
15.941
nmiss - do_loop
-0.161
-14.988
14.667
nmiss - compare
0.070
-14.757
14.897
nmiss - c_loop
0.953
-13.874
15.780
compare - do_loop
-0.231
-15.058
14.597
compare - nmiss
-0.070
-14.897
14.757
compare - c_loop
0.883
-13.944
15.710
c_loop - do_loop
-1.114
-15.941
13.713
c_loop - nmiss
-0.953
-15.780
13.874
c_loop - compare
-0.883
-15.710
13.944

*____             _
|  _ \ __ _ _   _| |
| |_) / _` | | | | |
|  __/ (_| | |_| | |
|_|   \__,_|\__,_|_|

;

Paul Dorfman via listserv.uga.edu
1:30 AM (7 hours ago)

 to SAS-L
Fried Egg,

It's just great: Thanks!

While at that, I've been anxious about not being able to find a standard SAS function that would get the leftmost non-null value from array ARR straight away - assuming, of course, for the generality sake, that after the first non-null there may be other n
like SCAN, FIND, and others do) to locate the index with the value *other* than the first argument. Alas! But finally it's dawned on my feeble brain that the compound expression:

WhichN (coalesce (of arr[*]), of arr[*])

will do just that. Naturally, I couldn't abstain from testing how it would stake up versus the rest of the techniques and hence concocted the code below. It includes the simple head-on scan, APP with COMPARE, your FIRSTNMISS, and WhichN+Coalesce expression

proc proto packet=work.func.proto ;
  double c_firstNMISS(double * p) ;
  externc c_firstNMISS ;
  double c_firstNMISS (double * p) {
  int i ;
  for (i = 0; ZMISS(p[i]); i++) {}
  return p[i] ;
  }
  externcend ;
run ;
quit ;

proc fcmp inlib=work.func outlib=work.func.fcmp ;
  function firstNMISS(dp[*]) ;
  return (c_firstNMISS(dp)) ;
  endsub ;
run ;

options cmplib=(work.func);

data _null_ ;
  retain iter 1e5 ;

  array arr [999] _temporary_ ;
  length comp $ %eval (999*8) ;
  comp = repeat (put (., rb8.), dim (arr) - 1) ;
  adr1 = addrlong (arr[1]) ;

  do i = dim(arr) to 1 by -99 ;
    arr[i] = i ;
  * scan ;
    t = time() ;
    do j = 1 to iter ;
      do Z = 1 by 1 until (N (arr[Z])) ;
      end ;
    end ;
    t_scan ++ (time() - t) ;
  * APPs ;
    t = time() ;
    do j = 1 to iter ;
      Z = ceil (compare (comp, peekclong (adr1, 7992)) / 8) ;
    end ;
    t_apps ++ (time() - t) ;
  * Fried Egg ;
    t = time() ;
    do j = 1 to iter ;
      Z = firstNmiss(arr) ;
    end ;
    t_fegg ++ (time() - t) ;
  * Coalesce + WhichN ;
    t = time() ;
    do j = 1 to iter ;
      Z = whichN (coalesce (of arr[*]), of arr[*]) ;
    end ;
    t_whch ++ (time() - t) ;
  end ;
  put (t_scan t_apps t_fegg t_whch) (=/) ;
run ;

The results for 1E5 iterations on my venerable laptop (W520 ThinkPad, X64_&PRO, i7/2.4Ghz/16G RAM/500G SSD) are below. Note the difference between V9.3 (TS Level 1M2) and V9.4 (TS Level 1M4).

V9.3:
--------------
t_scan=8.684
t_apps=3.245
t_fegg=1.261
t_whch=0.894

V9.4:
--------------
t_scan=10.222
t_apps=3.264
t_fegg=1.264
t_whch=0.923

Apart from the curiosity of 9.3 being faster than 9.4, I bet that if the WHICH* function had the K-modifier, it'd execute about twice faster.

Kind regards
--------------
Paul Dorfman
JAX, FL
--------------



*_____     _          _   _____
|  ___| __(_) ___  __| | | ____|__ _  __ _
| |_ | '__| |/ _ \/ _` | |  _| / _` |/ _` |
|  _|| |  | |  __/ (_| | | |__| (_| | (_| |
|_|  |_|  |_|\___|\__,_| |_____\__, |\__, |
                               |___/ |___/
;

Not hard to test it and see…
https://i.imgur.com/F4GnaUg.png
It would be good to note that while a portion of the difference between c_double and c_int is, as ra
proc proto packet=work.func.proto;
double c_iloop(double * p);
externc c_iloop;
double c_iloop(double * p) {
int i;
for (i = 0; ZMISS(p[i]); i++) {}
return p[i];
}
externcend;
double c_dloop(double * p);
externc c_dloop;
double c_dloop(double * p) {
double i;
for (i = 0; ZMISS(p[(int)i]); i++) {}
return p[(int)i];
}
externcend;
double c_diloop(double * p);
externc c_diloop;
double c_diloop(double * p) {
double i;
int j=0;
for (i = 0; ZMISS(p[j]); i++) {j++;}
return p[j];
}
externcend;
run;
method
Comparison
Difference
Between
Means
Simultaneous 95% Confidence
Limits
ds2_double - ds2_int
2.6136
2.1542
3.0730
ds2_double - traditional
9.8340
9.3539
10.3141
ds2_double - c_double
21.9887
21.5231
22.4544
ds2_double - c_doub/int
26.6520
26.1927
27.1114
ds2_double - c_int
27.2940
26.8457
27.7423
ds2_int - ds2_double
-2.6136
-3.0730
-2.1542
ds2_int - traditional
7.2204
6.7299
7.7109
ds2_int - c_double
19.3752
18.8988
19.8515
ds2_int - c_doub/int
24.0384
23.5683
24.5086
ds2_int - c_int
24.6804
24.2210
25.1397
traditional - ds2_double
-9.8340
-10.3141
-9.3539
traditional - ds2_int
-7.2204
-7.7109
-6.7299
traditional - c_double
12.1548
11.6584
12.6511
traditional - c_doub/int
16.8180
16.3276
17.3085
traditional - c_int
17.4600
16.9798
17.9401
c_double - ds2_double
-21.9887
-22.4544
-21.5231
c_double - ds2_int
-19.3752
-19.8515
-18.8988
c_double - traditional
-12.1548
-12.6511
-11.6584
c_double - c_doub/int
4.6633
4.1870
5.1396
c_double - c_int
5.3052
4.8395
5.7709
c_doub/int - ds2_double
-26.6520
-27.1114
-26.1927
c_doub/int - ds2_int
-24.0384
-24.5086
-23.5683
c_doub/int - traditional
-16.8180
-17.3085
-16.3276
c_doub/int - c_double
-4.6633
-5.1396
-4.1870
c_doub/int - c_int
0.6419
0.1825
1.1013
c_int - ds2_double
-27.2940
-27.7423
-26.8457
c_int - ds2_int
-24.6804
-25.1397
-24.2210
c_int - traditional
-17.4600
-17.9401
-16.9798
c_int - c_double
-5.3052
-5.7709
-4.8395
c_int - c_doub/int
-0.6419
-1.1013
-0.1825


/ __|/ _ \| '__/ _ \ '_ \
\__ \ (_) | | |  __/ | | |
|___/\___/|_|  \___|_| |_|

;

Paul,
Agreed, Fried Egg's WHICHN method is elegant and surprisingly fast;
certainly belongs in the SAS cookbook. But you write that the NMISS
method lacks generality because it fails if there are other missing values.
Which was not the case in the original problem. And if it was the case,
you may want to "left-fill" those also, which is exactly what my "dummy" method does.

While it may be very fun (and we all learned a lot, I think) to
optimize such SAS code, I think it is a waste of time in most real-life situations.
Much more important to have failsafe and generally usable code,
which is simple and easy to understand and maintain.

Regards,
Søren

*                  _
 _ __   __ _ _   _| |
| '_ \ / _` | | | | |
| |_) | (_| | |_| | |
| .__/ \__,_|\__,_|_|
|_|
;


Søren,

1. Fried Egg's method is the FIRSTNMISS function he's defined via proc PROTO.
Coalesce+WhichN method is merely a combo of two standard SAS list functions
I had to pair for the lack of the "K" modifier in the WhichN function. I suspect
each of them separately perform on par with NMISS, N, and the rest of their kin,
likely because they're based on the same underlying software algorit
hm - in principle, not much different from Fried Egg's FIRSTNMISS, but still 2-3
time faster (judging from my experiment) for the lack of
some user-defined function's overhead.

2. You're quite right about the way the problem was originally stated -
or, more precisely, how the sample data looked visually. Obviously, within
its confines the NMISS function is the fastest since it is (a) fast and (b)
the only one needed. I got interested in a more general case following the Nat's note.

3. I agree - in real life, a few seconds here and there matter less than code
simplicity and clarity. Yet there're situations where those seconds may
accumulate to the point where more optimization, albeit at the expense of
more complex code, is called for. And of course having fun coding esoteric
solutions is part and parcel of SAS-L, not to mention that sometimes they plant seeds
 of what may become mainstream in the future (hash is an example).

Best regards
Paul


