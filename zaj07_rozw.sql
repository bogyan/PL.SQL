-- Wyzwalacze bazowo-danowe

-- Wyzwalacz jest to program składowany w bazie danych, który jest uruchamiany przez system zarządzania bazą danych w momencie, w którym wystąpi zdarzenie, z którym wyzwalacz jest związany.

-- Zdarzenia, z którymi możemy wiązać wyzwalacze to m.in. operacje DML na tabeli (INSERT, UPDATE, DELETE) - tzw. wyzwalacze DML

-- 1. Wyzwalacze DML
  
-- Zdarzenia wyzwalające: INSERT, UPDATE, DELETE
-- Moment wykonania: BEFORE lub AFTER
-- Zakres: poleceniowy bądź wierszowy
-- poleceniowy: wykonywany raz dla całego polecenia
-- wierszowy: wykonywany dla każdego wiersza przetwarzanego przez polecenie

-- składnia

CREATE [OR REPLACE] TRIGGER nazwa_wyzwalacza
BEFORE|AFTER polecenie [OR polecenie][OR polecenie] ON nazwa_tabeli
[FOR EACH ROW]
[Declare
   sekcja deklaracji zmiennych]
BEGIN
  sekcja wykonywalna
[EXCEPTION
  sekcja obsługi wyjątków]
END;


-- przykład 1:
-- DROP TRIGGER DEPT_TRG1;
create or replace trigger DEPT_TRG1
before delete or update on departments
begin
   if to_char(sysdate,'HH24') between 15 and 23 then
      raise_application_error(-20001,'It is not possible to delete or update departments between 8 and 17');
   end if;
end; 

DELETE FROM DEPARTMENTS
WHERE DEPARTMENT_NAME = 'HR'
;

INSERT INTO DEPARTMENTS (DEPARTMENT_ID, DEPARTMENT_NAME, LOCATION_ID)
VALUES (145, 'HR', 1700);


-- przykład 2:
create or replace trigger EMP_SALARY_CONTROL_TRG
before update on employees
for each row
begin
   if :new.salary < :old.salary then
      raise_application_error(-20002,'Decreasing salary is forbidden');
   end if;
end;

update employees
set salary = 24000
where department_id = 10
;

-- select la
-- from employees
-- ;

-- Uwagi do pow. przykładów
-- 1. raise_application_error - procedura wbudowana w system Oracle umożliwiająca łatwe generowanie wyjątków powiązanych z numerami błędów
--    pierwszym parametrem jest nr błędu (numery od -20000 do -99999 są zarezerwowane własnie do takich operacji)
--    drugim parametrem jest komunikat, który chcemy związać z takim numerem błędu
   
-- 2. kwalifikatory :NEW i :OLD - mogą być stosowane w wyzwalaczach wierszowych (zarówno BEFORE, jak i AFTER)
--    składnia:
--    :NEW.kolumna_tabeli - nowa wartość w kolumnie
--    :OLD.kolumna tabeli - stara wartość w kolumnie
   
--    Oczywiście:
--    w wyzwalaczu odpalonym przez polecenie INSERT :OLD.kolumna jest zawsze NULL
--    w wyzwalaczu odpalonym przez polecenie DELETE :NEW.kolumna jest zawsze NULL
   
-- Pojedynczy wyzwalacz możemy związać z więcej, niż jedną operacją (przykład 1)
-- W kodzie wyzwalacza możemy rozpoznawać, która operacja spowodowała jego odpalenie poprzez użycie atrybutów
-- INSERTING, UPDATING, DELETING

-- przykład 3:

create or replace trigger DEPT_TRG1
before delete or update on departments
begin
   if UPDATING and to_char(sysdate,'HH24') between 15 and 23 then
      raise_application_error(-20001,'It is not possible to delete departments between 15 and 23');
   elsif DELETING then
      raise_application_error(-20003,'It is not possible to delete a departament');
   end if;
end; 


delete from departments;


-- Zastosowania wyzwalaczy DML
-- 1. Tworzenie reguł biznesowych, w przypadku których deklaratywne więzy integralności nie wystarczają
-- 2. Logowanie operacji wykonywanych na kluczowych tabelach (audyt)


-- 2. Wyzwalacze INSTEAD OF
-- Wyzwalacze te są pomocne w sytuacjach, w których chcielibyśmy zaimplementować operacje DML na perspektywach

-- składnia:

CREATE OR REPLACE TRIGGER nazwa_wyzwalacza
INSTEAD OF operation [OR operation][OR operation]
ON nazwa_perspektywy
[DECLARE
   sekcja_deklaracji_zmiennych]
BEGIN
   sekcja_wykonywalna
[EXCEPTION
   sekcja_obsługi_wyjątków]
END;

-- przykład:

create or replace view v_dept_loc_id as
select department_id, location_id 
from departments --zamienić na dcopy -> create table dcopy as select * from departments;
where department_id in (50, 60, 80);


create or replace trigger trg_v_dept_loc_id
instead of insert or update or delete on v_dept_loc_id
begin
    if inserting then
        insert into departments(department_id, department_name, location_id) 
            values (:new.department_id, 'NONAME', :new.location_id);
    elsif updating then
        if :new.department_id <> :old.department_id then
            raise_application_error(-20004,'You cannot modify primary key value');
        else
            update departments 
            set location_id = :new.location_id
            where department_id = :new.department_id;
        end if;
    elsif deleting then
        delete from departments
        where department_id = :old.department_id;
    end if;
end;


insert into v_dept_loc_id (department_id, location_id)
        values (345, 1700);

select *
from departments
where department_id = 345;

update v_dept_loc_id
set department_id = 123
where location_id = 1400
;

drop trigger DEPT_TRG1;

update v_dept_loc_id
set location_id = 123
where department_id = 50
;

select *
from v_dept_loc_id
;

delete from v_dept_loc_id
where department_id = 50
;

-- zadania

-- 1. Utwórz wyzwalacz wierszowy związany z operacjami DML na tabeli 
-- EMPLOYEES, który będzie ochraniał jej zawartość wg następujących reguł
--    - niedopuszczalne sa obniżki pensji
--    - niedopuszczalne są podwyżki pensji o więcej, niż 10%
--    - niedopuszczalne jest zatrudnianie pracownika bez podawania jego pensji lub z pensją większą, niż najniższa pensja na danym stanowisku
--    - niedopuszczalne są operacje DELETE poza ostatnim dniem miesiąca
drop table ecopy;

create table ecopy as
select *
from employees
;

create or replace trigger EMP_TRIG
before update or delete or insert on ecopy
for each row

declare
    min_sal number(10);
begin
    if inserting then
        select min(salary) into min_sal
        from employees
        where job_id = :new.job_id;

        if :new.salary is null or :new.salary > min_sal then
            raise_application_error(-20001, 'Salary is null or higher than min_sal');
        end if;
    elsif deleting and to_char(sysdate+1, 'dd') != '01' then
        raise_application_error(-20002, 'deleting rows is possible only last day of month') ;
    elsif updating and :new.salary < :old.salary then
        raise_application_error(-20003, 'new salary lower than old salary');
    elsif updating and :new.salary > :old.salary*1.1 then
        raise_application_error(-20004, 'new salary cant be higher than 10%*old one'); 
    end if;
end;




insert into ecopy (last_name, hire_date, email, salary, job_id)
    values ('Nowak2', sysdate, 'nowak@gmail', 10000, 'IT_PROG');

delete from ecopy;

update ecopy
set salary = 500
where last_name = 'King'
;

update ecopy
set salary = 50000
where last_name = 'King'

   
-- 2. Utwórz perspektywę V_EMP_DEPT, która będzie pokazywała numer departamentu i liczbę zatrudnionych w nim pracowników
-- 	Utwórz wyzwalacz INSTEAD OF na perspektywie V_EMP_DEPT, który będzie umożliwiał wykonanie na niej operacji DELETE
-- 	operacja ta będzie oznaczała usunięcie wszystkich pracowników z zadanego departamentu
drop table dcopy;

create table dcopy as
select *
from departments;

create or replace view V_EMP_DEPT as
select department_id, count(*) as liczba_pracownikow
from employees
group by department_id
;


create or replace trigger DEP_TRIG
instead of delete on V_EMP_DEPT
begin
    delete from dcopy
    where department_id = :old.department_id;
end;

delete from V_EMP_DEPT
where department_id = 10;


select *
from dcopy
where department_id = 10
;
