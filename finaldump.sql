--  USING MYSQL 8 DATABASE
-- This file contains all the DDL commands to create the tables required 
-- for FODB system. The foreign key references have on cascade updates.
-- This system shouldn't allow delete on any of the tables unless really required.


drop database if exists project;
create database if not exists project;
use project;

-- COMMAND FOR CREATING INSPECTOR TABLE 
-- The ID in Inspector table is stored as a character array of length 5 containing digits.
-- The table assumes that the name and hire date of inspector can not be NULL.
-- Since, ID of an inspector is unique, it has been selected as the primary key for the table.
drop table if exists inspector;

CREATE TABLE  Inspector (
   ID INT NOT NULL,
   Name VARCHAR(45) NOT NULL,
   HireDate DATE NOT NULL,
  PRIMARY KEY (ID));


delimiter $
CREATE TRIGGER delete_inspector before delete on Inspector
	for each row 
    begin
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT='Operation not allowed!';
    end;
    $
delimiter ;

  
-- Alter table inspector add column is_retired bit(1) default 0; 
Alter table inspector add column RetiredDate date default NULL;

select * from inspector;

-- COMMAND FOR CREATING BUILDER TABLE 
-- The License in builders table is stored as a character array of length 5 containing digits.
-- The table assumes that the name and address of inspector can not be NULL.
-- Since, License of a builder is unique, it has been selected as the primary key for the table.
drop table if exists builders;

CREATE TABLE  Builders (
	License INT NOT NULL,
    Name VARCHAR(30) NOT NULL,
    Address VARCHAR(40) NOT NULL,
  PRIMARY KEY (License));
  
-- COMMAND FOR CREATING INSPECTION TYPE TABLE 
-- The table assumes that the type and cost of type can not be NULL.
-- Since, code of a inspection type is unique, it has been selected as the primary key for the table.
drop table if exists Inspection_type;

CREATE TABLE  Inspection_type (
	Code CHAR(3) NOT NULL,
	Type VARCHAR(45) NOT NULL,
	PRIMARY KEY (Code));
   
delimiter $
CREATE TRIGGER delete_type before delete on Inspection_type
	for each row 
    begin
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT='Operation not allowed!';
    end;
    $
delimiter ;
    
CREATE TABLE INSP_CODE_COST (
    Code CHAR(3) NOT NULL,
    begin DATE NOT NULL,
    end DATE DEFAULT NULL,
    Cost int not null,
    PRIMARY KEY (Code , begin),
    FOREIGN KEY (code)
        REFERENCES Inspection_type (Code)
);
  
delimiter $
CREATE TRIGGER delete_cost before delete on INSP_CODE_COST
	for each row 
    begin
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT='Operation not allowed!';
    end;
    $
delimiter ;
  
-- COMMAND FOR CREATING PREREQUISITE TABLE 
-- The prerequisite table contains the information about the inspection types and its
-- prerequisite inspection types which reference the inspection types table
-- These foreign key references cascade on update.
  
drop table if exists Prerequisite;
  CREATE TABLE Prerequisite (
    Inspection_code CHAR(3) NOT NULL,
    Prerequisite_code CHAR(3) NOT NULL,
    FOREIGN KEY (Inspection_code)
        REFERENCES Inspection_type (Code)
        ON UPDATE CASCADE,
    FOREIGN KEY (Prerequisite_code)
        REFERENCES Inspection_type (Code)
        ON UPDATE CASCADE,
    UNIQUE (Inspection_code , Prerequisite_code)
);
    

delimiter $
CREATE TRIGGER delete_prereq before delete on prerequisite
	for each row 
    begin
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT='Operation not allowed!';
    end;
    $
delimiter ;

-- COMMAND FOR CREATING BUILDING TABLE 
-- Address size is chosen as 64 and type size is chosen as 32. The attributes like 
-- type, size, datefirstactivity has been chosen as NULL as they can take NULL values. 
-- The address of a building is chosen as its primary key. The builder_id references the 
-- builder that built the building. This implementation now assumes that a building can 
-- be built by only one builder. Since, address of a building is unique, it is chosen as the 
-- primary for the building table. The foreign key references have an on update cascade.

  drop table if exists Building;
  CREATE TABLE Building (
    Address VARCHAR(64) NOT NULL,
    Builder_ID INT NOT NULL,
    Type VARCHAR(32) DEFAULT NULL,
    Size INT DEFAULT NULL,
    DateFirstActivity DATE DEFAULT NULL,
    FOREIGN KEY (Builder_ID)
        REFERENCES Builders (License)
        ON UPDATE CASCADE,
    PRIMARY KEY (Address)
);

delimiter $
CREATE TRIGGER delete_building before delete on building
	for each row 
    begin
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT='Operation not allowed!';
    end;
    $
delimiter ;
    
-- COMMAND FOR CREATING INSPECTION_HISTORY TABLE
-- Inspection_history has an id which is an identity column and is primary key
-- for this table. All the other columns are assumed to be not NULL. The foreign key
-- references have an on update cascade.

drop table if exists Inspection_History;
CREATE TABLE Inspection_History (
    id INT AUTO_INCREMENT PRIMARY KEY,
    Date DATE NOT NULL,
    Type CHAR(3) NOT NULL,
    Inspector_ID INT NOT NULL,
    score INT,
    notes VARCHAR(128),
    building VARCHAR(64) NOT NULL,
    FOREIGN KEY (type)
        REFERENCES Inspection_type (Code)
        ON UPDATE CASCADE,
    FOREIGN KEY (Inspector_ID)
        REFERENCES Inspector (ID)
        ON UPDATE CASCADE,
    FOREIGN KEY (building)
        REFERENCES Building (Address)
        ON UPDATE CASCADE
);

delimiter $
CREATE TRIGGER delete_inspection_hist before delete on Inspection_history
	for each row 
    begin
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT='Operation not allowed!';
    end;
    $
delimiter ;

-- COMMAND FOR CREATING PENDING INSPECTIONS TABLE 
-- Pending inspections table has an id which is an identity column and 
-- is the primary key of the table. All other attributes are non NULL.
-- The foreign key references have an on update cascade.
drop table if exists pending_inspections;

CREATE TABLE pending_inspection (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    type CHAR(3) NOT NULL,
    building VARCHAR(64) NOT NULL,
    FOREIGN KEY (type)
        REFERENCES Inspection_type (Code)
        ON UPDATE CASCADE,
    FOREIGN KEY (building)
        REFERENCES Building (Address)
        ON UPDATE CASCADE
);

delimiter $
CREATE TRIGGER delete_pending before delete on pending_inspection
	for each row 
    begin
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT='Operation not allowed!';
    end;
    $
delimiter ;

-- Time for triggers

-- Checks if the id contains only numbers, if yes then pads with 1s to the left
-- and makes the length five. If not throws an error.
delimiter $
create procedure pad_id(inout id int)
begin
	if id between 0 and 100000 then
		set id = LPAD(id, 5, '1');
	else
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT='ID should be between 0 and 99999';
	end if;
end
$
delimiter;
  
-- The trigger checks on inspector table before insert if the id of the 
-- inspector contains only numbers and pads the left of the id with 1s
-- to make its length equal to 5 
  
delimiter $
CREATE TRIGGER ins_id before insert on Inspector
	for each row 
    begin
		call pad_id(new.id);
    end;
    $
delimiter ;


--  Trigger to check if cost can be negative
delimiter $
CREATE TRIGGER neg_cost before insert on insp_code_cost
	for each row 
    begin
		if new.cost < 0 then
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT='Cost can not be negative';
        end if;
    end;
    $
delimiter ;

--  Trigger to check if building size can be negative
delimiter $
CREATE TRIGGER neg_size before insert on building
	for each row 
    begin
		if new.size < 0 then
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT='Cost can not be negative';
        end if;
    end;
    $
delimiter ;

-- The trigger checks on inspector table before update if the id of the 
-- inspector contains only numbers and pads the left of the id with 1s
-- to make its length equal to 5 

delimiter $
CREATE TRIGGER ins_id_upd before update on Inspector
	for each row 
    begin
		call pad_id(new.id);
    end;
    $
delimiter ;

-- The trigger checks on builders table before insert if the license of the 
-- builder contains only numbers and pads the left of the id with 1s
-- to make its length equal to 5 

delimiter $
CREATE TRIGGER build_id before insert on Builders
	for each row 
    begin
		call pad_id(new.License);
	end;
$
delimiter ;


-- The trigger checks on builders table before update if the license of the 
-- builder contains only numbers and pads the left of the id with 1s
-- to make its length equal to 5 

delimiter $
CREATE TRIGGER build_id_upd before update on Builders
	for each row 
    begin
		call pad_id(new.License);
	end;
$
delimiter ;

-- The trigger checks on inspection type table before insert if the
-- code of the inspection type is 3 characters long

delimiter $
create trigger code_length_check before insert on Inspection_type
for each row
begin
	if char_length(new.code) != 3 then
		SIGNAL SQLSTATE '45000' 
		SET MESSAGE_TEXT = 'Inspection Code should be 3 character long.'; 
    end if;
end;
$
delimiter ;

-- The trigger checks on inspection type table before update if the
-- code of the inspection type is 3 characters long

delimiter $
create trigger code_length_check_upd before update on Inspection_type
for each row
begin
	if char_length(new.code) != 3 then
		SIGNAL SQLSTATE '45000' 
		SET MESSAGE_TEXT = 'Inspection Code should be 3 character long.'; 
    end if;
end;
$
delimiter ;


-- The trigger checks on prerequisite  table before insert if the
-- the type is the prerequisite to itself. I had an approach to solve the problem
-- when there is a loop i.e, a->b->c->a but couldn't implement it.

delimiter $
CREATE TRIGGER loop_prereq before insert on Prerequisite
	for each row 
    begin
		if new.Inspection_code = new.Prerequisite_code then
			SIGNAL SQLSTATE '45000' 
			SET MESSAGE_TEXT = "A type can not be prerequisite to itself!"; 
		end if;
	end;
$
delimiter ;


-- The trigger checks on prerequisite  table before update if the
-- the type is the prerequisite to itself. I had an approach to solve the problem
-- when there is a loop i.e, a->b->c->a but couldn't implement it.

delimiter $
CREATE TRIGGER loop_prereq_upd before update on Prerequisite
	for each row 
    begin
		if new.Inspection_code = new.Prerequisite_code then
			SIGNAL SQLSTATE '45000' 
			SET MESSAGE_TEXT = "A type can not be prerequisite to itself!";
		end if;
	end;
$
delimiter ;


-- The below procedures checks if an inspector has done more than 5
-- inpsections in a given month and year.  

delimiter $
create procedure check_five_inspections(in date1 date, in id char(5))
begin
	declare cnt int;
	set cnt = (select count(*) from Inspection_History where inspector_id = id
        AND month(date) = month(date1) and year(date) = year(date1));
	 if cnt >= 5 then
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT='Inspector can do at most 5 inspections per month';
        end if;
end
$
delimiter ;

-- The following procedure checks if the prerequisite of an inspection to be
-- inserted or updated is met

delimiter $
create procedure check_prereq(in code char(3), in location varchar(64))
begin
	declare prereq_count int;
	declare result_count int;
    
	set prereq_count = (select count(prerequisite_code) from prerequisite where Inspection_code = code);

	set result_count = (select count(prerequisite_code) from prerequisite where inspection_code = code 
									and prerequisite_code in 
									(select type from inspection_history 
									where building =  location 
									and score >= 75));

	if prereq_count <> result_count then
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT='Prerequisites not met';
	end if;
end
$
delimiter ;

-- A procedure to check if the score is between the values 0 and 100

delimiter $
create procedure check_score(in score int)
begin
	if score not between 0 and 100 then
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Score should be between 0 and 100';
    end if;
end
$
delimiter ;

-- A trigger to check if score is between values 0 and 100,
-- left pad 0 to the inspector id
-- check if the inspector has done five inspections in a given month and year
-- check if the prerequisites of the type is met

delimiter $
create trigger insp_hist before insert on Inspection_History
	for each row 
    begin
        call check_score(new.score);
        call pad_id(new.inspector_id);
        call check_five_inspections(new.date, new.inspector_id);
        call check_prereq(new.type, new.building);
    end;
$
delimiter ;


-- A procedure to reject score update.

DELIMITER $
create procedure score_update(in score_old int, in score_new int)
begin
	if score_old <> score_new then
		SIGNAL SQLSTATE '45000'
        SET message_text='Score can\'t be updated';
	end if;
end
$
delimiter ;

desc insp_code_cost;

-- delimiter $
-- create trigger check_end_ins before insert on insp_code_cost
-- 	for each row
--     begin
-- 		if new.end is null then
-- 			set new.end = date_add(new.begin, interval 15 year);
-- 		end if;
-- end ;
-- $
-- delimiter ;

-- delimiter $
-- create trigger check_end_upd before update on insp_code_cost
-- 	for each row
--     begin
-- 		if new.end is null then
-- 			set new.end = date_add(new.begin, interval 15 year);
-- 		end if;
-- end ;
-- $
-- delimiter ;

select * from insp_code_cost;

-- A trigger before update on inspection_history table to
-- pad inspector id if under update
-- reject operation if score is being updated
-- check if the prerequisite is being met
-- check if the inspector has done 5 inspections.
delimiter $
create trigger insp_update before update on Inspection_History
	for each row 
    begin
		if new.inspector_id <> old.inspector_id then
			call pad_id(new.inspector_id);
		end if;
		call score_update(old.score, new.score);
		call check_prereq(new.type, new.building);
		call check_five_inspections(new.date, new.inspector_id);
    end;
$
delimiter ;


drop function if exists get_cost;

delimiter $
create function get_cost(type char(3), date date)
returns int
deterministic
begin
	declare ret int;
    set ret = (select cost from insp_code_cost where date between begin and end and code = type);
    if ret is NULL then
		 set ret = (select cost from insp_code_cost where end is NULL and code = type);
    end if;
    return ret;
end;
$
delimiter ;

select * from insp_code_cost;

-- select cost from insp_code_cost where "2017-01-1" between "1983-01-01" and NULL and code = "FRM";

insert into inspector (id, Name, HireDate) values 
(101, 'Inspector-1', '1984-11-8'),
(102, 'Inspector-2', '1994-11-8'),
(103, 'Inspector-3', '2004-11-8'),
(104, 'Inspector-4', '2014-11-8'),
(105, 'Inspector-5', '2018-11-8')
;


insert into builders values
(12345, 'Builder-1', 'Address-1'),
(23456, 'Builder-2', 'Address-2'),
(34567, 'Builder-3', 'Address-3'),
(45678, 'Builder-4', 'Address-4'),
(12321, 'Builder-5', 'Address-5')
;

insert into Building 
(Address, Builder_ID, Type, Size, DateFirstActivity) values
('100 Main St., Dallas, TX', '12345', 'commercial', 250000, '1999-12-31'),
('300 Oak St., Dallas, TX', '12345', 'residential', 3000, '2000-1-1'),
('302 Oak St., Dallas, TX', '12345', 'residential', 4000, '2001-2-1'),
('304 Oak St., Dallas, TX', '12345', 'residential', 1500, '2002-3-1'),
('306 Oak St., Dallas, TX', '12345', 'residential', 1500, '2003-4-1'),
('308 Oak St., Dallas, TX', '12345', 'residential', 2000, '2003-4-1'),
('100 Industrial Ave., Fort Worth, TX', '23456', 'commercial', 100000, '2005-6-1'),
('101 Industrial Ave., Fort Worth, TX', '23456', 'commercial', 80000, '2005-6-1'),
('102 Industrial Ave., Fort Worth, TX', '23456', 'commercial', 75000, '2005-6-1'),
('103 Industrial Ave., Fort Worth, TX', '23456', 'commercial', 50000, '2005-6-1'),
('104 Industrial Ave., Fort Worth, TX', '23456', 'commercial', 80000, '2005-6-1'),
('105 Industrial Ave., Fort Worth, TX', '23456', 'commercial', 90000, '2005-6-1'),
('100 Winding Wood, Carrollton, TX', '45678', 'residential', 2500, null),
('102 Winding Wood, Carrollton, TX', '45678', 'residential', 2800, null),
('210 Cherry Bark Lane, Plano, TX', '12321', 'residentail', 3200, '2016-10-1'),
('212 Cherry Bark Lane, Plano, TX', '12321', 'residentail', null, null),
('214 Cherry Bark Lane, Plano, TX', '12321', 'residentail', null, null),
('216 Cherry Bark Lane, Plano, TX', '12321', 'residentail', null, null);


-- select * from building;

insert into inspection_type values
('FRM', 'Framing'),
('PLU', 'Plumbing'),
('POL', 'Pool'),
('ELE', 'Electrical'),
('SAF', 'Safety'),
('HAC', 'Heating/Cooling'),
('FNL', 'Final'),
('FN2', 'Final - 2 needed'),
('FN3', 'Final - plumbing'),
('HIS', 'Historical accuracy')
;



insert into insp_code_cost  values
('FRM', '1984-01-01', NULL, 100),
('PLU', '1984-01-01', NULL, 100),
('POL', '1984-01-01', NULL, 50),
('ELE', '1984-01-01', NULL, 100),
('SAF', '1984-01-01', NULL, 50),
('HAC', '1984-01-01', NULL, 100),
('FNL', '1984-01-01', NULL, 200),
('FN2', '1984-01-01', NULL, 150),
('FN3', '1984-01-01', NULL, 150),
('HIS', '1984-01-01', NULL, 100)
;

-- select get_cost('HIS', '2018-11-20');

select get_cost(inspection_history.type, inspection_history.date) from inspection_history;

-- SELECT * FROM INSPECTION_TYPE where cost = 100;

insert into prerequisite values
('PLU', 'FRM'),
('POL', 'PLU'),
('ELE', 'FRM'),
('HAC', 'ELE'),
('FNL', 'HAC'),
('FNL', 'PLU'),
('FN2', 'ELE'),
('FN2', 'PLU'),
('FN3', 'PLU')
;

-- Removed some rows in the excel sheet that were causing errors and moved them below. Data is sorted with respect to date and then inserted
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-01',	'FRM',	103,	100,	'no problems noted',	'100 Winding Wood, Carrollton, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-01',	'FRM',	101,	100,	'no problems noted',	'300 Oak St., Dallas, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-01',	'FRM',	102,	100,	'no problems noted',	'302 Oak St., Dallas, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-02',	'PLU',	101,	90,	'minor leak, corrected',	'300 Oak St., Dallas, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-02',	'PLU',	102,	25,	'massive leaks',	'302 Oak St., Dallas, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-03',	'ELE',	101,	80,	'exposed junction box',	'300 Oak St., Dallas, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-04',	'HAC',	101,	80,	'duct needs taping',	'300 Oak St., Dallas, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-05',	'FNL',	101,	90,	'ready for owner',	'300 Oak St., Dallas, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-08',	'PLU',	102,	50,	'still leaking',	'302 Oak St., Dallas, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-12',	'FRM',	103,	85,	'no issues but messy',	'210 Cherry Bark Lane, Plano, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-12',	'PLU',	102,	80,	'no leaks, but messy',	'302 Oak St., Dallas, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-14',	'SAF',	104,	100,	'no problems noted',	'210 Cherry Bark Lane, Plano, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-14',	'ELE',	102,	100,	'no problems noted',	'302 Oak St., Dallas, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-20',	'PLU',	103,	100,	'everything working',	'100 Winding Wood, Carrollton, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-10-25',	'ELE',	103,	100,	'no problems noted',	'100 Winding Wood, Carrollton, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-01',	'FRM',	103,	100,	'no problems noted',	'102 Winding Wood, Carrollton, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-01',	'HAC',	102,	80,	'duct needs taping',	'302 Oak St., Dallas, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-02',	'HAC',	103,	100,	'no problems noted',	'100 Winding Wood, Carrollton, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-02',	'PLU',	103,	90,	'minor leak, corrected',	'102 Winding Wood, Carrollton, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-02',	'FRM',	105,	100,	'tbd',	'105 Industrial Ave., Fort Worth, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-02',	'FNL',	102,	90,	'ready for owner',	'302 Oak St., Dallas, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-03',	'ELE',	103,	80,	'exposed junction box',	'102 Winding Wood, Carrollton, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-04',	'PLU',	103,	80,	'duct needs sealing',	'210 Cherry Bark Lane, Plano, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-05',	'POL',	105,	90,	'ready for owner',	'210 Cherry Bark Lane, Plano, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-06',	'FRM',	105,	100,	'okay',	'100 Industrial Ave., Fort Worth, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-08',	'PLU',	102,	100,	'no leaks',	'100 Industrial Ave., Fort Worth, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-12',	'POL',	102,	80,	'pool equipment okay',	'100 Industrial Ave., Fort Worth, TX');
insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-14',	'FN3',	102,	100,	'no problems noted',	'100 Industrial Ave., Fort Worth, TX');
--  rejected
-- insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) values ('2018-11-14',	'FNL',	103,	90,	'REJECT TOO MANY',	'100 Winding Wood, Carrollton, TX');


INSERT INTO `project`.`pending_inspection` (`date`, `type`, `building`) VALUES ('2018/9/1', 'FNL', '105 Industrial Ave., Fort Worth, TX');
INSERT INTO `project`.`pending_inspection` (`date`, `type`, `building`) VALUES ('2018/10/26', 'FRM', '212 Cherry Bark Lane, Plano, TX');
INSERT INTO `project`.`pending_inspection` (`date`, `type`, `building`) VALUES ('2018/11/4', 'PLU', '212 Cherry Bark Lane, Plano, TX');



-- 1.	List all buildings (building#, address, type) that have not passed a final (FNL, FN2, FN3) inspection.
-- Query: 
select b.address from building b where b.address not in
(select building from inspection_history where score >= 75 and type like 'FN%');


-- 2.	List the id, name of inspectors who have given at least one failing score.
-- Query:
 select id, name from inspector where id in
(select inspector_id from inspection_history where score < 75);

-- 3.	What inspection type(s) have never been failed?
-- Query:
 select code from inspection_type where code not in (
select type from inspection_history where score < 75);

-- 4.	What is the total cost of all inspections for builder 12345?
-- Query: 
select sum(get_cost(it.code, ih.date)) from inspection_type it join 
 inspection_history ih on it.code = ih.type where ih.building in
(select bl.address from building bl where bl.builder_id=12345);

-- 5.	What is the average score for all inspections performed by Inspector 102?
-- Query: 
select avg(score) from inspection_history where inspector_id  = 11102;


-- 6.	How much revenue did FODB receive for inspections during October 2018?
-- Query: 
select sum(get_cost(it.code, ih.date)) from inspection_type it join
inspection_history ih on ih.type = it.code where month(date) = 10 and year(date)=2018;

-- 7.	How much revenue was generated in 2018 by inspectors with more than 15 years seniority?
-- Query: 
select sum(get_cost(it.code, ih.date)) from inspection_type it join
inspection_history ih on it.code = ih.type join
inspector i on i.id = ih.inspector_id where i.hiredate < date_add(sysdate(), interval -15 year);


-- 8.	Demonstrate the adding of a new 1600 sq ft residential building for builder #34567, located at 1420 Main St., Lewisville TX.
-- Queries:
select * from building where builder_id=34567;
insert into building values ('1420 Main St., Lewisville, TX', 34567, 'residential', 1600, NULL);
select * from building where builder_id=34567;

-- 9.	Demonstrate the adding of an inspection on the building you just added. This framing inspection occurred on 11/21/2018 by inspector 104, with a score of 50, and note of “work not finished.”
-- Query: 
start transaction;
	update building set datefirstactivity = '2018-11-21' where 
      address = '1420 Main St., Lewisville, TX';
	insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) 
	values ('2018-11-21', 'FRM', 104, 50, 'work not finished', '1420 Main St., Lewisville, TX');
commit;


-- 10.	Demonstrate changing the cost of an ELE inspection changed to $150 effective today.  

select * from insp_code_cost;

start transaction;
    update insp_code_cost set end = '2018-11-19' where code = 'ELE' and end is NULL;
	insert into insp_code_cost values 
    ('ELE', '2018-11-20', NULL, 150);
commit;

select * from insp_code_cost;

-- 11.	Demonstrate adding of an inspection on the building you just added. This electrical inspection occurred on 11/22/2018 by inspector 104, with a score of 60, and note of “lights not completed.”

insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) 
values ('2018-11-22', 'ELE', 104, 60, 'lights not completed', '1420 Main St., Lewisville, TX');


-- 12.	Demonstrate changing the message of the FRM inspection on 11/2/2018 by inspector #105 to “all work completed per checklist.”

UPDATE inspection_history  SET  notes = 'all work completed per checklist'
WHERE inspector_id = 11105 AND date = '2018-11-02' AND type = 'FRM';


select * from inspection_history where notes like 'all work completed per checklist';

-- 13.	Demonstrate the adding of a POL inspection by inspector #103 on 11/28/2018 on the first building associated with builder 45678.


select * from building where builder_id = 45678;

insert into Inspection_History (Date, Type, Inspector_id, score, notes, building) 
values ('2018-11-28', 'POL', 103, NULL, NULL, '100 Winding Wood, Carrollton, TX');

update inspector set RetiredDate = '2018-12-1'
where id =11101;

select * from inspector where retireddate is not null;











