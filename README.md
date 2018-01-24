# utl_fill_missing_values_with_the_first_non-missing_value_in_a_row
Fill missing values with the first non-missing value in a row. 
    Fill missing values with the first non-missing value in a row

    WPS/SAS same results;

    https://goo.gl/gs3VBv
    https://communities.sas.com/t5/Base-SAS-Programming/Fill-missing-values-with-the-first-non-missing-value-in-a-row/m-p/429346

    * very slight non important change (brackets '[]' instead of '()' to avoid
      accidental function;
    novinosrin profile
    https://communities.sas.com/t5/user/viewprofilepage/user-id/138205

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
    
    Paul,
    
       *
     ___  ___  _ __ ___ _ __
    / __|/ _ \| '__/ _ \ '_ \
    \__ \ (_) | | |  __/ | | |
    |___/\___/|_|  \___|_| |_|

    ;
    You are right, my primitive solution (which on the other hand has the advantage of being easier to understand and maintain, and more     general) is quite a lot slower than your suggested solutions.
    
    But the fastest way to find the left-most non-missing seems to be NMISS:
    data want_x;
      set have;
      array t(*) t:;
      _N_=nmiss(of t(*));
      if 0<_N_<dim(t) then
        call pokelong (repeat (put (t(_N_+1),rb8.), _N_), addrlong(t1));
    run;

    This is the fastest solution I have yet tried with your data. And it also works with special missing values, but of course not with     non-contiguous arrays or character arrays.

    I tested, and there seemed to be a performance gain by precalculating the addrlong result, but not very much.

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

