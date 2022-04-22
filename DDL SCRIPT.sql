create database covid19managementfinal;

use covid19managementfinal;

----------------------vaccination center table definition------------------------------------

CREATE TABLE VACCINATIONCENTER
(
    CENTERID INTEGER NOT NULL,
    CENTERNAME VARCHAR(100),
    ADDRESS VARCHAR(100),
    CONTACT bigint,
    EMAIL VARCHAR(100),
    UNITSAVAILABLE INTEGER,
    PERDAYCAPACITY INTEGER,
    CONSTRAINT PK_VC PRIMARY KEY (CENTERID)
);

-------------------------vendor table definition------------------------------------

CREATE TABLE VENDOR
(
    VENDORLIC INTEGER NOT NULL,
    NAME VARCHAR(30),
    ADDRESS VARCHAR(100),
    CONTACT bigint,
    QUANTITY INTEGER,
    EMAIL VARCHAR(50),
    TRANSPORTMODE VARCHAR(20),
    SHIPMENTDATE DATE,
    CONSTRAINT PK_VENDOR PRIMARY KEY (VENDORLIC)
);

----------------- manufacturer table definition ------------------------------------

CREATE TABLE MANUFACTURER
(
    MANUFACTURERID INTEGER NOT NULL,
    NAME VARCHAR(30),
    ADDRESS VARCHAR(100),
    CONTACT bigint,
    VACCINETYPE VARCHAR(30),
    DAILYCAPACITY INTEGER,
    EMAIL VARCHAR(100),
    CONSTRAINT PK_MANUFACTURER PRIMARY KEY (MANUFACTURERID)
);

----------------------check constraint 1--------------------------------------
ALTER TABLE MANUFACTURER
ADD CONSTRAINT CHK_VACCINETYPE check (VACCINETYPE in ('Pfizer','Moderna','Covishield')) ;

------------------------ customer table definition --------------------------

CREATE TABLE CUSTOMER
(
    CUSTOMERID INTEGER NOT NULL,
    CUSTOMERNAME VARCHAR(30),
    DOB DATE,
    GENDER VARCHAR(10),
    CONTACT BIGINT,
    EMAIL VARCHAR(50),
    SSN INTEGER,
    DOSENUMBER INTEGER,
    CONSTRAINT PK_CUSTOMER PRIMARY KEY (CUSTOMERID)
);
----------------------- check constraint 2 ------------------------------

ALTER TABLE CUSTOMER
ADD CONSTRAINT CHK_DOSENUMBER1 check (DOSENUMBER in (1,2,3)) ;


------------------------- insurance table definition -----------------------

CREATE TABLE INSURANCE
(
    INSURANCEID INTEGER NOT NULL,
    COMPANYNAME VARCHAR(20),
    CUSTOMERID INTEGER,
    INSURANCETYPE VARCHAR(20),
    INSURANCECOVERAGE VARCHAR(20),
    INSURANCEDURATION INTEGER,
    INSURANCECOST INTEGER,
    CONSTRAINT PK_INSURANCE PRIMARY KEY (INSURANCEID),
    CONSTRAINT FK_INSURANCE FOREIGN KEY (CUSTOMERID) REFERENCES CUSTOMER(CUSTOMERID)
);

---------------------- employee table definition -----------------------------

CREATE TABLE EMPLOYEE
(
    EMPLOYEEID INTEGER NOT NULL,
    EMPLOYEENAME VARCHAR(30),
    GENDER VARCHAR(10),
    DOB DATE,
    CONTACT BIGINT,
    CHAMBERNUMBER varchar(10),
    EMAIL VARCHAR(30),
    DAYSAVAILABLE INTEGER,
    VACCCENTERID INTEGER,
    EMPLOYEETYPE VARCHAR(20),
    CONSTRAINT PK_EMPLOYEE PRIMARY KEY(EMPLOYEEID),
    CONSTRAINT FK_EMPLOYEE1 FOREIGN KEY (VACCCENTERID) REFERENCES VACCINATIONCENTER(CENTERID)
);
----------------------- check constraint 3 ---------------------------------
ALTER TABLE EMPLOYEE
ADD CONSTRAINT CHK_EMPLOYEETYPE check (EMPLOYEETYPE in ('DOCTOR','STAFF'));


----------------------------  vaccine batch table definition --------------------------                                              

CREATE TABLE VACCINEBATCH
(
    BATCHNUMBER INT NOT NULL,
    NAME VARCHAR(50),
    VACCINETYPE VARCHAR(30),
    MANUFACTUREDATE DATE,
    USEBEFORE DATE,
    MANUFACTURERID INTEGER,
    CONSTRAINT PK_VB PRIMARY KEY (BATCHNUMBER),
    CONSTRAINT FK_VB FOREIGN KEY(MANUFACTURERID) REFERENCES MANUFACTURER(MANUFACTURERID)
);
------------------------ check constraint 4 --------------------------------
ALTER TABLE VACCINEBATCH
ADD CONSTRAINT CHK_VACCINEBATCH check (VACCINETYPE in ('Pfizer','Moderna','Covishield')) ;

---------------------- operations table definition --------------------------

create table OPERATIONS
(
    CENTERID INTEGER,
    VENDORLIC INTEGER ,
    MANUFACTURERID INTEGER,
    BATCHNUMBER INTEGER,
    DELIVERYDATE DATE,
    [STATUS] VARCHAR(25),
    CONSTRAINT FK_OPERATIONS1 FOREIGN KEY (CENTERID) REFERENCES VACCINATIONCENTER(CENTERID),
    CONSTRAINT FK_OPERATIONS2 FOREIGN KEY (VENDORLIC) REFERENCES VENDOR(VENDORLIC),
    CONSTRAINT FK_OPERATIONS3 FOREIGN KEY (MANUFACTURERID) REFERENCES MANUFACTURER(MANUFACTURERID),
    CONSTRAINT FK_OPERATIONS4 FOREIGN KEY (BATCHNUMBER) REFERENCES VACCINEBATCH(BATCHNUMBER)
);

------------------------- doctor table definition ------------------------------------
CREATE TABLE DOCTOR
(
    DOCTORID INTEGER NOT NULL,
    SPECIALIZATION VARCHAR(30),
    DOCTORLICNO INTEGER,
    CONSTRAINT PK_DOCTOR PRIMARY KEY(DOCTORID)
);
-------------------------- staff table definition -----------------------------------
CREATE TABLE STAFF
(
    STAFFID INTEGER NOT NULL,
    DEPARTMENT VARCHAR(30),
    CONSTRAINT PK_STAFF PRIMARY KEY (STAFFID)
);
-------------------------- vaccine record table definition ---------------------------------

CREATE TABLE VACCINERECORD
(
    VACCCARDNUMBER INTEGER NOT NULL,
    VACCINETYPE VARCHAR(30),
    BATCHNUMBER INTEGER,
    VACCDATE DATE,
    DOSENUMBER INTEGER,
    DOCTORID INTEGER,
    CENTERID INTEGER,
    CUSTOMERID INTEGER,
    CONSTRAINT PK_VR PRIMARY KEY (VACCCARDNUMBER),
    CONSTRAINT FK_VR1 FOREIGN KEY (BATCHNUMBER) REFERENCES VACCINEBATCH(BATCHNUMBER),
    CONSTRAINT FK_VR2 FOREIGN KEY (DOCTORID) REFERENCES DOCTOR(DOCTORID),
    CONSTRAINT FK_VR3 FOREIGN KEY (CENTERID) REFERENCES VACCINATIONCENTER(CENTERID),
    CONSTRAINT FK_VR4 FOREIGN KEY (CUSTOMERID) REFERENCES CUSTOMER(CUSTOMERID)
);


ALTER TABLE VACCINERECORD
ADD CONSTRAINT CHK_VACCINRECORD check (VACCINETYPE in ('Pfizer','Moderna','Covishield')) ;

ALTER TABLE VACCINERECORD
ADD CONSTRAINT CHK_DOSENUMBER check (DOSENUMBER in (1,2,3)) ;

------- DML Trigger------- +3 DAYS ADDITION TO DELIVERY DATE WHEN INSERT STATEMENT IS RUN-------------------------------

create trigger datemodification
on OPERATIONS
for INSERT
as
BEGIN
    update operations set deliverydate = dateadd(DAY,3,o_Date)
from ( select CENTERID CID, VENDORLIC VLIC, MANUFACTURERID MID, BATCHNUMBER BN, DELIVERYDATE O_Date
        from inserted) QUERY
where operations.centerid = query.cid and operations.vendorlic = query.VLIC
end;

------------------------------------- stored procedure 1 ---------------------------------

----Customer details based on vaccination date and time------
----Input : Vaccination Date 
----Output : Customer details

Create procedure CustomerDetails @a Datetime
As
Begin
Select c.CUSTOMERID,c.CUSTOMERNAME,c.CONTACT,c.EMAIL, v.VACCDATE,v.VACCINETYPE, v.CENTERID , va.CENTERNAME
From CUSTOMER c
Inner Join VACCINERECORD v
on c.CUSTOMERID=v.CUSTOMERID 
Inner Join VACCINATIONCENTER va
on v.CENTERID=va.CENTERID

where
v.VACCDATE=@a
End

------------------------------- procedure execution 1 -------------------------------

DECLARE @RC int
DECLARE @a datetime

EXECUTE @RC = [dbo].[CustomerDetails] 
   @a='2021-04-03'
GO


-------------------------------STORED PROCEDURE 2 ---------------------------

----Vendor Information based on VendorID----------------------------
----Input: VendorID
----Output: Vendor Lic no, Vendor Name , Vaccination center and Delivery date

Create Procedure VendorInformation @vendorID int as

BEGIN
	select v.VENDORLIC, v.NAME, o.CENTERID as VaccinationCenter, o.DELIVERYDATE 
    from VENDOR v join  OPERATIONS o
	on v.VENDORLIC = o.VENDORLIC
	where v.VENDORLIC = @vendorID

END

----------------------------- procedure execution 2 ---------------------------
DECLARE @RC int
DECLARE @vendorID int



EXECUTE @RC = [dbo].[VendorInformation] 
   @vendorID='1983'
GO

------------------------------STORED PROCEDURE 3 ------------------------------

----Update number of vaccine units available-----
----Input : Vaccination center ID
----Output : Decrements the Units of Available vaccine by 1

Create Procedure VacUnits @Center int
AS
BEGIN

update VACCINATIONCENTER
set UNITSAVAILABLE = UNITSAVAILABLE - 1 where UNITSAVAILABLE > 0 AND CENTERID=@Center;
 
END

---------------------------- procedure execution 3------------------------------
DECLARE @RC int
DECLARE @Center int


EXECUTE @RC = [dbo].[VacUnits] 
   @Center=348722
GO

select * from vaccinationcenter where centerid = 348722;

------------------------------ STORED PROCEDURE 4 -----------------------------------
----To get the available list of vaccines in a given batch by a given manufacturer------
----Input: Batch Number and Manufacturer ID
----Output : Batch number, available vaccine type and manufacturer details

create Procedure getVacList
@batch int,
@manfid int 
AS  
BEGIN
select b.BATCHNUMBER, b.NAME,b.VACCINETYPE, m.MANUFACTURERID, m.NAME
from VACCINEBATCH b INNER JOIN MANUFACTURER m
ON b.MANUFACTURERID = m.MANUFACTURERID
WHERE b.BATCHNUMBER=@batch AND m.MANUFACTURERID=@manfid

END
------------------------ procedure execution 4 -------------------------------

DECLARE @RC int
DECLARE @batch int
DECLARE @manfid int
EXECUTE @RC = [dbo].[getVacList] 
   @batch=153
  ,@manfid=12
GO

------------------------ STORED PROCEDURE 5 -----------------------------------
--------Change the status of the Vaccine Batch------
--------Input : Batch number
--------Output : Batch number, Batch name, Status

Create procedure BatchStatusDelivery
    @batch int
As
Begin
    DECLARE @A int,
        @DateDelivery date ,
        @ShipmentDate date
    SET @A=(select VENDORLIC
    from OPERATIONS
    where BATCHNUMBER=@batch)
    SET @DateDelivery=(Select DELIVERYDATE
    from OPERATIONS
    where BATCHNUMBER=@batch)
    SET @ShipmentDate=(Select SHIPMENTDATE
    from VENDOR
    where VENDORLIC=@A )
    IF @DateDelivery=@ShipmentDate     
BEGIN
        UPDATE OPERATIONS
SET STATUS = 'Delivered'
WHERE BATCHNUMBER=@batch;
    END
ELSE IF @DateDelivery<@ShipmentDate 
BEGIN
        UPDATE OPERATIONS
SET STATUS = 'Transit'
WHERE  BATCHNUMBER=@batch;
    END
END
----------------------- procedure execution 5-----------------------
EXECUTE BatchStatusDelivery @batch=78;
SELECT * FROM OPERATIONS where batchnumber= 78;

----------------------- USER DEFINED FUNCTION 1 -------------------
----Function to get the number of doses taken by each customer ----

CREATE FUNCTION GetDosesTaken (@CUSTOMERID int) 
RETURNS int 
AS 
BEGIN
    DECLARE @DosesTaken int
    SELECT @DosesTaken = CUSTOMER.DOSENUMBER
    FROM CUSTOMER
    WHERE CUSTOMER.CUSTOMERID = @CUSTOMERID
    RETURN @DosesTaken
END;

SELECT dbo.GetDosesTaken ('30202') AS DOSES_TAKEN;

----------------------------------------- USER DEFINED FUNCTION 2 -------------------
-------Function to get the daily production capacity of manufacturers ---------------

CREATE FUNCTION GetProductionCapacity (@MANUFACTURERID int) 
RETURNS int 
AS 
BEGIN
    DECLARE @DailyCapacity int
    SELECT @DailyCapacity = MANUFACTURER.DAILYCAPACITY
    FROM MANUFACTURER
    WHERE MANUFACTURER.MANUFACTURERID = @MANUFACTURERID
    RETURN @DailyCapacity
END;


SELECT dbo.GetProductionCapacity ('12') AS PRODUCTION_CAPACITY;

-------------------------- COMPUTED COLUMN BASED ON UDF 3 ------------------------------------
-------Function to get the number of days that the vaccine units available can sustain -------

CREATE FUNCTION GetNumberOfDays (@CENTERID int) 
RETURNS int 
AS 
BEGIN 
      DECLARE @Days int 
      SELECT @Days = (VACCINATIONCENTER.UNITSAVAILABLE) / (VACCINATIONCENTER.PERDAYCAPACITY) 
      FROM VACCINATIONCENTER  
      WHERE VACCINATIONCENTER.CENTERID = @CENTERID 
      RETURN @Days 
END;

SELECT dbo.GetNumberOfDays ('634356') AS NUMBER_OF_DAYS;

------------ COMPUTED COLUMN BASED ON UDF 4 -------------------------
-----Function to get the monthly average cost of insurance ----------

CREATE FUNCTION GetMonthlyCost (@INSURANCEID int) 
RETURNS int 
AS 
BEGIN
    DECLARE @MonthlyCost int
    SELECT @MonthlyCost = (INSURANCE.INSURANCECOST) / (INSURANCE.INSURANCEDURATION)
    FROM INSURANCE
    WHERE INSURANCE.INSURANCEID = @INSURANCEID
    RETURN @MonthlyCost
END;

SELECT dbo.GetMonthlyCost ('128') AS MONTHLY_COST;
-------------------- UDF 5 --------------------------------------------------
-------Function to get the quantities of vaccines that the vendors have------

CREATE FUNCTION GetVaccineQuantity (@VENDORLIC int)
RETURNS int
AS
BEGIN
    DECLARE @Quantity int
    SELECT @Quantity = VENDOR.QUANTITY
    FROM VENDOR
    WHERE VENDOR.VENDORLIC = @VENDORLIC
    RETURN @Quantity
END;

SELECT dbo.GetVaccineQuantity ('1983') AS VACCINE_QUANTITY;

------------------------- NON-CLUSTERED INDEX-----------------------------------

CREATE NONCLUSTERED INDEX CustomerID_IND
ON CUSTOMER(CUSTOMERID,CUSTOMERNAME);

Create NONCLUSTERED Index EMPLOYEE_IND
ON EMPLOYEE(EMPLOYEEID,EMPLOYEENAME);

Create NONCLUSTERED Index Insurance_IND
on INSURANCE(INSURANCEID,COMPANYNAME,INSURANCETYPE,INSURANCECOVERAGE);

--------------------------- VIEW 1 ---------------------------------------------

CREATE VIEW [Vendors above Avg Quantity]
as
    select vendorlic, name, quantity
    from vendor
    where quantity> (select avg(quantity)
    from vendor);

select * from [Vendors above Avg Quantity];

------------------------- VIEW 2 -----------------------------

CREATE VIEW CAPU
AS
    SELECT CENTERID, CENTERNAME, PERDAYCAPACITY, UNITSAVAILABLE
    FROM VACCINATIONCENTER
    WHERE PERDAYCAPACITY > 55
        AND PERDAYCAPACITY < 85
        AND UNITSAVAILABLE < 1000
        AND UNITSAVAILABLE > 800;


SELECT * FROM CAPU;

----------------------VIEW 3 ------------------------------

CREATE VIEW DOSE7
AS
    SELECT CUSTOMERNAME, DOB, DOSENUMBER, GENDER
    FROM CUSTOMER
    WHERE DOSENUMBER>1
        AND GENDER = 'Male'
        AND CUSTOMERNAME = 'Virat Kohli';

SELECT * FROM DOSE7;

------------------------------ VIEW 4 --------------------------

CREATE VIEW QUANTITY2
AS
    SELECT VENDORLIC, ADDRESS, QUANTITY, TRANSPORTMODE
    FROM VENDOR
    WHERE QUANTITY>5000
        AND TRANSPORTMODE = 'Ground';

SELECT * FROM QUANTITY2;

--------------------- COLUMN ENCRYPTION -----------------------------------
----------encryption of dose numbers --------------------------------
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Covid@123';

CREATE CERTIFICATE Certificatecovid
WITH SUBJECT = 'Protect Dose';

CREATE SYMMETRIC KEY key_covid  
WITH ALGORITHM = AES_128 
ENCRYPTION BY CERTIFICATE Certificatecovid;

ALTER TABLE Customer  
ADD coviddosenumberencrypt varbinary(MAX) NULL;

OPEN SYMMETRIC KEY key_covid 
DECRYPTION BY CERTIFICATE Certificatecovid;

UPDATE CUSTOMER
SET coviddosenumberencrypt = EncryptByKey (Key_GUID('key_covid'),DOSENUMBER);

CLOSE SYMMETRIC KEY key_covid;

OPEN SYMMETRIC KEY key_covid 
DECRYPTION BY CERTIFICATE Certificatecovid;

SELECT customerid, customername, coviddosenumberencrypt AS 'Encrypted Dose Number',
    CONVERT(varchar, DecryptByKey(coviddosenumberencrypt)) AS 'Decrypted Dose Number'
FROM Customer; 

--------------------------------- END -------------------------------