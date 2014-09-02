LIBNAME TTN_LIB "C:\games\Kaggle\Titanic\";
RUN;

PROC IMPORT OUT=TTN_LIB.TITANIC_SET
	DATAFILE="C:\games\Kaggle\Titanic\train.csv"
	DBMS=csv
	REPLACE;
    getnames=yes;
RUN;

DATA TTN_LIB.TITANIC_SET;
	set TTN_LIB.TITANIC_SET;
	if Age = . then Age = 29.6991176;
	if (Pclass = 1 AND Fare = .) then Fare = 84.1546875;
	if (Pclass = 2 AND Fare = .) then Fare = 20.6621832;
	if (Pclass = 3 AND Fare = .) then Fare = 13.6755501;
	if Sex = "female" then Sex10 = 1; else Sex10=0;
	if Pclass = 1 then class1 = 1; else class1 = 0;
	if Pclass = 2 then class2 = 1; else class2 = 0;
	if Pclass = 1 then payratio = fare/84.1546875;
	if Pclass = 2 then payratio = fare/20.6621832;
	if Pclass = 3 then payratio = fare/13.6755501;
	if payratio > 1.5 then expensive = 1; else expensive = 0;
	if payratio < 0.5 then cheap = 1; else cheap = 0;
	if embarked = " " then embarked = "S";
	if embarked = "C" then EmbCher=1; else EmbCher=0;
	if embarked = "Q" then EmbQuee=1; else EmbQuee=0;
	if index(Name,'Master') > 0 then master = 1; else master = 0;
	if (index(Name,'Miss') > 0 OR index(Name,'Mlle') > 0)
		then miss = 1; else miss = 0;
	if index(Name,'Mrs') > 0 then mrs = 1; else mrs = 0;
RUN;

proc means data = TTN_LIB.TITANIC_SET (KEEP= Pclass fare) MIN MEAN MAX;
	class Pclass;
run;

PROC LOGISTIC DATA=TTN_LIB.TITANIC_SET 
		OUTMODEL=TTN_LIB.LOGITRESULT;
	MODEL Survived (event='1') = Parch EmbCher master miss mrs
			  expensive class1 class2;
	TITLE 'Titanic Survival Logit Model ';
RUN;

PROC IMPORT OUT=TTN_LIB.TEST_SET
	DATAFILE="C:\games\Kaggle\Titanic\test.csv"
	DBMS=csv
	REPLACE;
    getnames=yes;
RUN;

DATA TTN_LIB.TEST_SET;
	set TTN_LIB.TEST_SET;
	if Age = . then Age = 29.6991176;
	if (Pclass = 1 AND Fare = .) then Fare = 84.1546875;
	if (Pclass = 2 AND Fare = .) then Fare = 20.6621832;
	if (Pclass = 3 AND Fare = .) then Fare = 13.6755501;
	if Sex = "female" then Sex10 = 1; else Sex10=0;
	if Pclass = 1 then class1 = 1; else class1 = 0;
	if Pclass = 2 then class2 = 1; else class2 = 0;
	if Pclass = 1 then payratio = fare/84.1546875;
	if Pclass = 2 then payratio = fare/20.6621832;
	if Pclass = 3 then payratio = fare/13.6755501;
	if payratio > 1.5 then expensive = 1; else expensive = 0;
	if payratio < 0.5 then cheap = 1; else cheap = 0;
	if embarked = " " then embarked = "S";
	if embarked = "C" then EmbCher=1; else EmbCher=0;
	if embarked = "Q" then EmbQuee=1; else EmbQuee=0;
	if index(Name,'Master') > 0 then master = 1; else master = 0;
	if (index(Name,'Miss') > 0 OR index(Name,'Mlle') > 0)
		then miss = 1; else miss = 0;
	if index(Name,'Mrs') > 0 then mrs = 1; else mrs = 0;
RUN;

proc logistic inmodel=TTN_LIB.LOGITRESULT;
  score clm data = TTN_LIB.TITANIC_SET OUT=TTN_LIB.LOGITPRED_TRAIN;
run;

proc logistic inmodel=TTN_LIB.LOGITRESULT;
  score clm data = TTN_LIB.TEST_SET OUT=TTN_LIB.LOGITPRED;
run;

DATA TTN_LIB.LOGITPRED;
	SET TTN_LIB.LOGITPRED;
	RENAME I_Survived = Survived;
	if P_1 > 0.44 then My_Survived = 1; else My_Survived = 0; 
RUN;

DATA TTN_LIB.LOGITPRED_TRAIN;
	SET TTN_LIB.LOGITPRED_TRAIN;
	RENAME I_Survived = Pred_Survived;
	if P_1 > 0.44 then My_Survived = 1; else My_Survived = 0; 
RUN;

/*
PROC PRINT DATA=TTN_LIB.LOGITPRED_TRAIN (KEEP = PassengerID Survived 
		Pred_Survived My_Survived);
	SUM Survived My_Survived;
RUN;
*/

proc sql;
    create view TTN_LIB.vw_ds1 as 
        select PassengerId,Survived from TTN_LIB.LOGITPRED;
quit;

proc export data=TTN_LIB.vw_ds1
   outfile="C:\games\Kaggle\Titanic\output.csv"
   dbms=csv
   replace;
run;
