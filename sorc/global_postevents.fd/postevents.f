C$$$  MAIN PROGRAM DOCUMENTATION BLOCK
C
C MAIN PROGRAM: GLOBAL_POSTEVENTS
C   PRGMMR: DONG             ORG: NP22        DATE: 2020-08-20
C
C ABSTRACT: INTERPOLATES GLOBAL SPECTRAL SIMGA ANALYSIS TO PREPBUFR
C   OBSERVATION LOCATIONS, ENCODES THEM INTO PREPBUFR REPORTS AND
C   WRITES OUT A FINAL POSTPROCESSED VERSION OF THE PREPBUFR FILE.
C   THE BULK OF THE WORK IS DONE BY THE W3LIB ROUTINE "GBLEVENTS"
C   WHICH RUNS HERE IN A "POSTEVENTS" MODE.
C
C PROGRAM HISTORY LOG:
C 1999-07-02  D. A. KEYSER -- ORIGINAL AUTHOR
C 1999-09-26  D. A. KEYSER -- CHANGES TO MAKE CODE MORE PORTABLE
C 2001-10-10  D. A. KEYSER -- MODIFIED TO NOW PASS TWO SPANNING
C             GLOBAL SIGMA ANALYSIS FILES INTO W3LIB ROUTINE
C             GBLEVENTS IN SITUATIONS WHERE THE CENTER DATE FOR THE
C             PREPBUFR FILE HAS AN HOUR THAT IS NOT A MULTIPLE OF 3
C             (SEE 2001-10-10 CHANGES TO GBLEVENTS)
C 2013-03-13  D. A. KEYSER -- CHANGES TO RUN ON WCOSS: SET BUFRLIB
C             MISSING (BMISS) TO 10E8 RATHER THAN 10E10 TO AVOID
C             INTEGER OVERFLOW; USE FORMATTED PRINT STATEMENTS WHERE
C             PREVIOUSLY UNFORMATTED PRINT WAS > 80 CHARACTERS
C 2020-08-20  J. DONG -- MODIFIED PIVOT YEAR FROM 20 TO 40 TO
C             HANDLE 2-DIGIT YEARS THAT DO NOT DESIGNATE 19 OR 20
C             FOR CENTURY.
C
C USAGE:
C   INPUT FILES:
C     UNIT 11  - PREPBUFR FILE
C     UNIT 12  - FIRST INPUT SPECTRAL (GLOBAL) SIGMA ANALYSIS FILE; IF
C              - HOUR IN CENTER DATE FOR PREPBUFR FILE IS A MULTIPLE
C              - OF 3 THEN THIS FILE IS VALID AT THE CENTER DATE OF THE
C              - PREPBUFR FILE, IF THE HOUR IN CENTER DATE FOR PREPBUFR
C              - FILE IS NOT A MULTIPLE OF 3 THEN THIS FILE IS VALID AT
C              - THE CLOSEST TIME PRIOR TO THE CENTER DATE OF THE
C              - PREPBUFR FILE THAT IS A MULTIPLE OF 3
C     UNIT 13  - SECOND INPUT SPECTRAL (GLOBAL) SIGMA ANALYSIS FILE; IF
C              - HOUR IN CENTER DATE FOR PREPBUFR FILE IS A MULTIPLE
C              - OF 3 THEN THIS FILE IS EMPTY, IF THE HOUR IN CENTER
C              - DATE FOR PREPBUFR FILE IS NOT A MULTIPLE OF 3 THEN
C              - THIS FILE IS VALID AT THE CLOSEST TIME AFTER THE
C              - CENTER DATE OF THE PREPBUFR FILE THAT IS A MULTIPLE OF
C              - 3
C     UNIT 15  - EXPECTED CENTER DATE IN PREPBUFR FILE IN FORM
C                YYYYMMDDHH
C
C   OUTPUT FILES:
C     UNIT 06  - STANDARD OUTPUT PRINT
C     UNIT 51  - PREPBUFR FILE (NOW CONTAINING ANALYZED VALUES)
C
C   SUBPROGRAMS CALLED:
C       W3NCO    - W3TAGB    W3TAGE    ERREXIT
C       W3EMC    - GBLEVENTS
C       BUFRLIB  - DATELEN   OPENBF    READMG    OPENMB
C                - WRITSB    CLOSBF    SETBMISS  GETBMISS
C
C   EXIT STATES:
C     COND =   0 - SUCCESSFUL RUN
C     COND =  21 - DATE DISAGREEMENT BETWEEN ACTUAL CENTER DATE IN
C                  PREPBUFR FILE AND EXPECTED CENTER DATE READ IN
C                  FROM UNIT 15
C     COND =  22 - BAD OR MISSING DATE READ IN FROM UNIT 15
C     COND =  60-79 - RESERVED FOR W3LIB ROUTINE GBLEVENTS (SEE
C                      GBLEVENTS DOCBLOCK)
C
C
C REMARKS: NONE.
C
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 90
C   MACHINE:  NCEP WCOSS
C
C$$$

      PROGRAM GLOBAL_POSTEVENTS

      REAL(8)   BMISS,GETBMISS

      DIMENSION IUNITA(2)

      CHARACTER*8  SUBSET,LAST

      DATA  LAST/'XXXXXXXX'/

      CALL W3TAGB('GLOBAL_POSTEVENTS',2020,0233,0061,'NP22')

      PRINT 700
  700 FORMAT(/'  =====> WELCOME TO POSTEVENTS PROGRAM -- LAST UPDATED ',
     $ '2020-08-20'/)

C  On WCOSS should always set BUFRLIB missing (BMISS) to 10E8 to avoid
C   overflow when either an INTEGER*4 variable is set to BMISS or a
C   REAL*8 (or REAL*4) variable that is missing is NINT'd
C  -------------------------------------------------------------------
ccccc CALL SETBMISS(10E10_8)
      CALL SETBMISS(10E8_8)
      BMISS=GETBMISS()
      print *
      print *, 'BUFRLIB value for missing is: ',bmiss
      print *

      IUNITI    = 11
      IUNITA(1) = 12
      IUNITA(2) = 13
      IUNITD    = 15
      IUNITP    = 51

C  OPEN INPUT PREPBUFR FILE JUST TO GET MESSAGE DATE (WHICH IS THE
C   ACTUAL CENTER DATE), LATER CLOSE FILE
C  ---------------------------------------------------------------

      CALL DATELEN(10)

      CALL OPENBF(IUNITI,'IN',IUNITI)
      CALL READMG(IUNITI,SUBSET,IDATEP,IRET)

      PRINT 53, IDATEP
   53 FORMAT(/' --> ACTUAL   CENTER DATE OF PREPBUFR FILE READ FROM ',
     $ ' SEC. 1 MESSAGE DATE IS:',I11/)

      IF(IDATEP.LT.1000000000)  THEN

C If 2-digit year returned in IDATEP, must use "windowing" technique
C  to create a 4-digit year

C IMPORTANT: IF DATELEN(10) IS CALLED, THE DATE HERE SHOULD ALWAYS
C            CONTAIN A 4-DIGIT YEAR, EVEN IF INPUT FILE IS NOT
C            Y2K COMPLIANT (BUFRLIB DOES THE WINDOWING HERE)

         PRINT *, '##> THE FOLLOWING SHOULD NEVER HAPPEN!!!!!'
         PRINT'(" ##> 2-DIGIT YEAR IN IDATEP RETURNED FROM READMG ",
     $    "(IDATEP IS: ",I0,") - USE WINDOWING TECHNIQUE TO OBTAIN ",
     $    "4-DIGIT YEAR")', IDATEP
C IF IDATEP=41~99 THEN IDATEP=1941~1999
C IF IDATEP=00~40 THEN IDATEP=2000~2040
         IF(IDATEP/1000000.GT.40)  THEN
            IDATEP = 1900000000 + IDATEP
         ELSE
            IDATEP = 2000000000 + IDATEP
         ENDIF
         PRINT *, '##> CORRECTED IDATEP WITH 4-DIGIT YEAR, IDATEP NOW',
     $    ' IS: ',IDATEP
      ENDIF

C  READ IN EXPECTED CENTER DATE OF PREPBUFR FILE
C  ---------------------------------------------

      REWIND IUNITD
      READ(IUNITD,'(6X,I10)',END=904,ERR=904)  IDATED
      PRINT 3, IUNITD, IDATED
    3 FORMAT(/' --> EXPECTED CENTER DATE OF PREPBUFR FILE READ FROM ',
     $ 'UNIT',I3,' IS:',13X,I11/)

C  CHECK ACTUAL CENTER DATE OF PREPBUFR FILE VS. EXPECTED CENTER DATE
C  ------------------------------------------------------------------

      IF(IDATEP.NE.IDATED)  GO TO 901

      CALL CLOSBF(IUNITI)

C  OPEN INPUT AND OUTPUT PREPBUFR FILES FOR DATA PROCESSING
C  --------------------------------------------------------

      CALL OPENBF(IUNITI,'IN ',IUNITI)
      CALL OPENBF(IUNITP,'OUT',IUNITI)

C----------------------------------------------------------------------
C----------------------------------------------------------------------
      NEWTYP = 0

C  LOOP THROUGH THE INPUT MESSAGES
C  -------------------------------

      DO WHILE(IREADMG(IUNITI,SUBSET,JDATEP).EQ.0)
         IF(SUBSET.NE.LAST)  THEN
            NEWTYP = 1
cppppp
            print *, 'New input message type read in: ',SUBSET
cppppp
         END IF

         CALL OPENMB(IUNITP,SUBSET,JDATEP)
         DO WHILE(IREADSB(IUNITI).EQ.0)

C  COPY DECODED REPORT FROM INPUT PREPBUFR FILE TO OUTPUT PREPBUFR FILE
C  --------------------------------------------------------------------

            CALL UFBCPY(IUNITI,IUNITP)

C  CALL W3LIB ROUTINE GBLEVENTS TO ENCODE ANALYZED VALUES FOR THIS RPT
C  -------------------------------------------------------------------

            CALL GBLEVENTS(IDATED,IUNITA,0,IUNITP,0,SUBSET,NEWTYP)

C  WRITE THIS REPORT (SUBSET) INTO BUFR MESSAGE IN OUTPUT PREPBUFR FILE
C  --------------------------------------------------------------------

            CALL WRITSB(IUNITP)

            NEWTYP = 0

         ENDDO

         LAST = SUBSET

      ENDDO

C  CLOSE THE BUFR FILES
C  --------------------

      CALL CLOSBF(IUNITI)
      CALL CLOSBF(IUNITP)

C  ALL DONE
C  --------

      CALL W3TAGE('GLOBAL_POSTEVENTS')

      STOP
C-----------------------------------------------------------------------

  901 CONTINUE
      PRINT 9901, IDATEP,IDATED
 9901 FORMAT(/' ##> ACTUAL CENTER DATE OF INPUT PREPBUFR FILE (',I10,
     $ ') DOES NOT MATCH EXPECTED CENTER DATE (',I10,') - STOP 21'/)
      CALL W3TAGE('GLOBAL_POSTEVENTS')
      CALL ERREXIT(21)

C-----------------------------------------------------------------------

  904 CONTINUE
      PRINT 9902, IUNITD
 9902 FORMAT(/' ##> BAD OR MISSING EXPECTED PREPBUFR CENTER DATE ',
     $ 'READ FROM UNIT',I3,' - STOP 22'/)
      CALL W3TAGE('GLOBAL_POSTEVENTS')
      CALL ERREXIT(22)

C-----------------------------------------------------------------------

      END
