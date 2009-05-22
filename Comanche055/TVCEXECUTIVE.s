# Copyright:	Public domain.
# Filename:	TVCEXECUTIVE.s
# Purpose:	Part of the source code for Colossus 2A, AKA Comanche 055.
#		It is part of the source code for the Command Module's (CM)
#		Apollo Guidance Computer (AGC), for Apollo 11.
# Assembler:	yaYUL
# Contact:	Ron Burkey <info@sandroid.org>.
# Website:	www.ibiblio.org/apollo.
# Pages:	945-950
# Mod history:	2009-05-12 RSB	Adapted from the Colossus249/ file of the
#				same name, using Comanche055 page images.
#		2009-05-20 RSB	Corrections:  CAE -> CAF in one place.
#		2009-05-21 RSB	In 1SHOTCHK, a CAF SEVEN was corrected to 
#				CAF SIX.
#
# This source code has been transcribed or otherwise adapted from digitized
# images of a hardcopy from the MIT Museum.  The digitization was performed
# by Paul Fjeld, and arranged for by Deborah Douglas of the Museum.  Many
# thanks to both.  The images (with suitable reduction in storage size and
# consequent reduction in image quality as well) are available online at
# www.ibiblio.org/apollo.  If for some reason you find that the images are
# illegible, contact me at info@sandroid.org about getting access to the 
# (much) higher-quality images which Paul actually created.
#
# Notations on the hardcopy document read, in part:
#
#	Assemble revision 055 of AGC program Comanche by NASA
#	2021113-051.  10:28 APR. 1, 1969  
#
#	This AGC program shall also be referred to as
#			Colossus 2A

# Page 945
# PROGRAM NAME....	TVCEXECUTIVE, CONSISTING OF TVCEXEC, NEEDLEUP, VARGAINS
#			1SHOTCHK, REPCHEK, CG.CORR, COPYCYCLES, ETC.
# LOG SECTION....	TVCEXECUTIVE		SUBROUTINE ....DAPCSM
# MOD BY SCHLUNDT				21 OCTOBER 1968
#
# FUNCTIONAL DESCRIPTION....
#      *A SELF-PERPETUATING WAITLIST TASK AT 1/2 SECOND INTERVALS WHICH:
#	PREPARES THE ROLL WITH OGA (CDUX)
#	PREPARES THE ROLL FDAI NEEDLE (FLY-TO  OGA ERROR)
#	PREPARES THE ROLL PHASE PLANE  OGAERR  (FLY-FROM  OGA ERROR)
#	PREPARES THE TVC ROLLDAP TASK WAITLIST CALL (3 CS DELAY)
#	UPDATES THE NEEDLES DISPLAY
#	UPDATES THE VEHICLE MASS AND CALLS MASSPROP TO UPDATE INERTIA DATA
#	UPDATES PITCH, YAW, AND ROLL DAP GAINS FROM MASSPROP DATA
#	PERFORMS ONE-SHOT CORRECTION FOR TMC LOOP 0-3 SEC AFTER IGNITION
#	PERFORMS REPETITIVE UPDATES FOR THE TMC LOOP AFTER THE ONE-SHOT CORR.
#
# CALLING SEQUENCE....
#      *TVCEXEC CALLED AS A WAITLIST TASK, IN PARTICULAR BY TVCINIT4 AND BY
#	ITSELF, BOTH AT 1/2 SECOND INTERVALS
#
# NORMAL EXIT MODE.... TASKOVER
#
# ALARM OR ABORT EXIT MODES.... NONE
#
# SUBROUTINES CALLED....NEEDLER, S40.15, MASSPROP, TASKOVER, IBNKCALL
#
# OTHER INTERFACES....
#      *TVCRESTART PACKAGE FOR RESTARTS
#      *PITCHDAP, YAWDAP FOR VARIABLE GAINS AND ENGINE TRIM ANGLES
#
# ERASABLE INITIALIZATION REQUIRED....
#      *SEE TVCDAPON....TVCINIT4
#      *VARK AND 1/CONACC (S40.15 OF R03)
#      *PAD LOAD EREPFRAC
#      *BITS 15,14 OF FLAGWRD6 (T5 BITS)
#      *TVCEXPHS FOR RESTARTS
#      *ENGINE-ON BIT (11.13) FOR RESTARTS
#      *CDUX, OGAD
#
# OUTPUT....
#      *ROLL DAP OGANOW, FDAI NEEDLE= (AK). AND PHASE PLANE OGAERR
#      *VARIABLE GAINS FOR PITCH/YAW AND ROLL TVC DAPS
#      *SINGLE-SHOT AND REPETITIVE CORRECTIONS TO ENGINE TRIM ANGLES
#	PACTOFF AND YACTOFF
#
# DEBRIS....	MUCH, BUT SHAREABLE WITH RCS/ENTRY, ALL IN EBANK6

# Page 946
		BANK	16
		SETLOC	DAPROLL
		BANK
		EBANK=	BZERO
		COUNT*	$$/TVCX
		
TVCEXEC		CS	FLAGWRD6	# CHECK FOR TERMINATION (BITS 15,14 READ
		MASK	OCT60000	#	10 FROM TVCDAPON TO RCSDAPON)
		EXTEND
		BZMF	TVCEXFIN	# TERMINATE
		
		CAF	.5SEC		# W.L. CALL TO PERPETUATE TVCEXEC
		TC	WAITLIST
		EBANK=	BZERO
		2CADR	TVCEXEC
		
ROLLPREP	CAE	CDUX		# UPDATE ROLL LADDERS (NO NEED TO RESTART-
		XCH	OGANOW		# 	PROTECT, SINCE ROLL DAPS RE-START)
		XCH	OGAPAST
		
		CAE	OGAD		# PREPARE ROLL FDAI NEEDLE WTIH FLY-TO
		EXTEND			#	ERROR (COMMAND - MEASURED)
		MSU	OGANOW
		TS	AK		# FLY-TO OGA ERROR, SC.AT B-1 REVS
		
		EXTEND			# PREPARE ROLL DAP PHASE PLANE OGAERR
		MP	-BIT14	
		TS	OGAERR		# PHASE-PLANE (FLY-FROM) OGAERROR,
					#	SC.AT B+0 REVS
		
		CAF	THREE		# SET UP ROLL DAP TASK (ALLOW SOME TIME)
		TC	WAITLIST
		EBANK=	BZERO
		2CADR	ROLLDAP
		
NEEDLEUP	TC	IBNKCALL	# DO A NEEDLES UPDATE (RETURNS AFTER CADR)
		CADR	NEEDLER		#	(NEEDLES RESTARTS ITSELF)

VARGAINS	CAF	BIT13		# CHECK ENGINE-ON BIT TO INHIBIT VARIABLE
		EXTEND			#	GAINS AND MASS IF ENGINE OFF
		RAND	DSALMOUT	# CHANNEL 11
		CCS	A
		TCF	+4		#	ON, SO OK TO UPDATE GAINS AND MASS
	+5	CAF	TWO		#	OFF, SO BYPASS MASS/GAIN UPDATES,
		TS	TVCEXPHS	#		ALSO ENTRY FROM CCS BELOW WITH
		TCF	1SHOTCHK	#		VCNTR = -0 (V97 R40 ENGFAIL)
		CCS	VCNTR		# 	TEST FOR GAIN OF UPDATE TIME
		TCF	+4		#		NOT YET
# Page 947		
		TCF	GAINCHNG	#		NOW
		TCF	+0		#		NOT USED
		TCF	VARGAINS +5	#		NO, LOTHRUST (S40.6 R40)
		
	+4	TS	VCNTRTMP	#	PROTECT VCNTR AND
		CAE	CSMMASS		#	CSMMASS DURING AN IMPULSIVE BURN
		TS	MASSTMP
		TCF	EXECCOPY
		
GAINCHNG	TC	IBNKCALL	# UPDATE IXX, IAVG, IAVG/TLX
		CADR	FIXCW		# MASSPROP ENTRY (ALREADY INITIALIZED)
		TC	IBNKCALL	# UPDATE 1/CONACC, VARK
		CADR	S40.15		#	(S40.15 IS IN TVCINITIALIZE)
		CS	TENMDOT		# UPDATE MASS FOR NEXT 10 SEC. OF BURN
		AD	CSMMASS
		TS	MASSTMP		# KG B+16
		
		CAF	NINETEEN	# RESET THE VARIABLE-GAIN UPDATE COUNTER
		TS	VCNTRTMP

EXECCOPY	INCR	TVCEXPHS	# RESTART-PROTECT TEH COPYCYCLE		(1)

		CAE	MASSTMP		# CSMMASS KG B+16
		TS	CSMMASS
		
		CAE	VCNTRTMP	# VCNTR
		TS	VCNTR
		TS	V97VCNTR	# FOR ENGFAIL (R41) MASS UPATES AT SPSOFF
		
		INCR	TVCEXPHS	# COPYCYCLE OVER			(2)
		
1SHOTCHK	CCS	CNTR		# CHECK FOR ONE-SHOT OR REPCORR
		TCF	+4		#	NOT YET
		TCF	1SHOTOK		#	NOW
		TCF	REPCHEK		#	ONE-SHOT OVER, ON TO REPCORR
		TCF	1SHOTOK		#	NOW (ONE-SHOT ONLY, NO REPCORR)
		
	+4	TS	CNTRTMP		# COUNT DOWN
		CAF	SIX		# SETUP TVCEXPHS FOR ENTRY AT CNTRCOPY
		TS	TVCEXPHS
		TCF	CNTRCOPY
		
REPCHEK		CAE	REPFRAC		# CHECK FOR REPETITIVE UPDATES
		EXTEND
		BZMF	TVCEXFIN	#	NO  (NEG OR +-ZERO)
		TS	TEMPDAP +1	#	YES, SET UP CORRECTION FUNCTION
		CAF	FOUR		# SET UP TVCEXPHS FOR ENTRY AT CORSETUP
		TS	TVCEXPHS
		TCF	CORSETUP
# Page 948		
1SHOTOK		CAF	BIT13		# CHECK ENGINE-ON BIT, NOT PERMITTING
		EXTEND			#	SWITCHOVER DURING ENGINE-SHUTDOWN
		RAND	DSALMOUT
		CCS	A
		TCF	+2		# 	ONE-SHOT OK
		TCF	TVCEXFIN	# 	NO, TERMINATE
		
		INCR	TVCEXPHS	#					(3)
		
# RSB 2009.  The following instruction was previously "CAE FCORFRAC", but FCORFRAC
# is not in erasable memory as implied by the use of CAE.  I've accordingly changed
# it to CAF instead to indicate fixed memory.
TEMPSET		CAF	FCORFRAC	# 	SET UP CORRECTION FRACTION
		TS	TEMPDAP +1
		
		INCR	TVCEXPHS	# ENTRY FROM REPCHECK AT NEXT LOCATION	(4)
		
CORSETUP	CAE	DAPDATR1	# CHECK FOR LEM-OFF/ON
		MASK	BIT13		# (NOTE, SHOWS LEM-OFF)
		EXTEND
		BZF	+2		# LEM IS ON,  PICK UP   TEMPDAP+1
		CAE	TEMPDAP +1	# LEM IS OFF, PICK UP 2(TEMPDAP+1)
		AD	TEMPDAP +1
		TS	TEMPDAP		# CG.CORR USES TEMPDAP
		
		CAF	NEGONE		# SET UP FOR CNTR = -1 (SWTCHOVR DONE)
		TS	CNTRTMP		#	(COPYCYCLE AT "CNTRCOPY")
		
CG.CORR		EXTEND			# PITCH TMC LOOP
		DCA	PDELOFF
		DXCH	PACTTMP
		EXTEND
		DCS	PDELOFF
		DDOUBL
		DDOUBL
		DXCH	TTMP1
		EXTEND
		DCA	DELPBAR
		DDOUBL
		DDOUBL
		DAS	TTMP1
		EXTEND
		DCA	TTMP1
		EXTEND
		MP	TEMPDAP
		DAS	PACTTMP
		
		EXTEND			# YAW TMC LOOP
		DCA	YDELOFF
		DXCH	YACTTMP
		EXTEND
		DCS	YDELOFF
		DDOUBL
# Page 949		
		DDOUBL
		DXCH	TTMP1
		EXTEND
		DCA	DELYBAR
		DDOUBL
		DDOUBL
		DAS	TTMP1
		EXTEND
		DCA	TTMP1
		EXTEND
		MP	TEMPDAP
		DAS	YACTTMP
		
CORCOPY		INCR	TVCEXPHS	# RESTART-PROTECT THE COPYCYCLE		(5)

		EXTEND			# TRIM-ESTIMATES, AND
		DCA	PACTTMP
		TS	PACTOFF		#	TRIMS
		DXCH	PDELOFF
		
		EXTEND
		DCA	YACTTMP
		TS	YACTOFF
		DXCH	YDELOFF
		
		INCR	TVCEXPHS	# ENTRY FROM 1SHOTCHK AT NEXT LOCATION	(6)
		
CNTRCOPY	CAE	CNTRTMP		# UPDATE CNTR (RESTARTS OK, FOLLOWS CPYCY)
		TS	CNTR
		
TVCEXFIN	CAF	ZERO		# RESET TVCEXPHS
		TS	TVCEXPHS		
		TCF	TASKOVER	# TVCEXECUTIVE FINISHED

FCORFRAC	OCT	10000		# ONE-SHOT CORRECTION FRACTION	

# Page 950 (page is empty)

