-- Dynamiczny SQL
-- --------------
-- Dynamiczny SQL jest parsowany w trakcie wykonywania programu, a nie na etapie jego kompilacji.
-- Ze składniowego punktu widzenia polecenia dynamicznego SQL są ciągami znaków (literałami znakowymi, wartościami typu VARCHAR2).

-- Ma zastosowanie wszędzie tam, gdzie chcielibyśmy ominąć ograniczenia związane z zanurzaniem poleceń SQL w programach PL/SQL
-- - tworzyć programy PL/SQL, które będą w stanie wykonywać instrukcje DDL
-- - parametryzować instrukcje DML/SELECT np. nazwami tabel


-- 1. Zagnieżdżone tablice (nested tables)
--    Nested tables są podobne do tablic PL/SQL, ale
--    - przy deklaracji typu nested table nie deklarujemy typu indeksu
--    - Nested tables mogą być składowane w kolumnie tabeli w bazie danych
   
--    Tablicami takimi w programach PL/SQL możemy się posługiwać w taki sam sposób, jak zwykłymi tablicami PL/SQL
   
--    Składnia
--    a. typ
   TYPE typ_nested_table IS TABLE OF typ_elementu
   
--    b. zmienna
   zmienna_nested_table typ_nested_table
   
--    przykład:
   create or replace procedure read_all_rows
   is
   	type emp_type is table of employees%rowtype;
   	
   	emp_table emp_type;
   begin
      ...
   end;
   
   
-- 2. instrukcja EXECUTE IMMEDIATE
-- Służy ona do wykonywania instrukcji dynamicznego SQL

-- składnia

EXECUTE IMMEDIATE 'instrukcja_sql';

-- np

create or replace procedure delete_all_rows(p_table_name varchar2)
is
begin
   execute immediate 'delete from '||p_table_name;
   commit;
end;
/

select *
from user_tables;

select *
from STUDENTS;

begin
    delete_all_rows('STUDENTS');
end;

-- 2. klauzula BULK COLLECT INTO
-- klauzula ta pozwala na wykonanie dynamicznego rozkazu SELECT 
-- i zwrócenie wyników do tablicy zagnieżdżonej

-- składnia:
EXECUTE IMMEDIATE dynamiczny_rozkaz_select BULK COLLECT INTO zmienna_tablicowa

-- przykład
create or replace procedure read_all_rows(p_table_name varchar2)
is
	type emp_type is table of employees%rowtype;
	emp_table emp_type;
begin
   execute immediate 'select * from '||p_table_name 
                                        bulk collect into emp_table;
   
   for i in 1..emp_table.last loop
   	dbms_output.put_line(emp_table(i).last_name);
   end loop;
end;

begin
    read_all_rows('EMPLOYEES');
end;

create table emp1000 as
select *
from employees
where department_id = 10;

begin
    read_all_rows('EMP1000');
end;

-- 3. parametryzacja dynamicznego SQLa zmiennymi wiązanymi
--    a. zmienne wiązane (bind variables)
  
--    W przypadku dynamicznego SQLa stosujemy notację pozycyjną, tzn. nie nazywamy w tekście polecenia SQL zmiennych wiązanych, a jedynie podajemy ich numery, poprzedzając dwukropkiem
--    np.
   
   'UPDATE EMPLOYEES SET SALARY = :1 WHERE EMPLOYEE_ID = :2'
   
--    b. parametryzacja dynamicznego SQL
   
--    W celu sparametryzowania polecenia dynamicznego SQLa zmiennymi wiązanymi, musimy zastosować klauzulę USING lista zmiennych
   
--    składnia
   
   EXECUTE IMMEDIATE 'tekst rozkazu SQL posługujący się zmiennymi wiązanymi' USING zmienna1, zmienna2, ... ;
   
--    zmienna1, zmienna2, ... to zwykłe zmienne lub parametry programu PL/SQL. Ich liczba oraz odpowiednie typy muszą się pokrywać z liczbą i odpowiednimi typami zmiennych WIĄZANYCH
--    wykorzystanych w tekście rozkazu dynamicznego SQLa 
   
--    np.
create or replace procedure update_salary(p_emp_id employees.employee_id%type, p_salary employees.salary%type)
is
-- v_char1 varchar2(20);
-- v_char2 employees.last_name%type;
begin
    execute immediate 'update employees 
                        set salary = :1 
                        where employee_id = :2'
                        using p_salary,  p_emp_id;
end;
   
begin
    update_salary(100, 30000);
end;
   
-- zadania
-- 1. napisz procedurę backup_table, której zadaniem będzie 
--stworzenie kopii zadanej tabeli przy pomocy polecenia 
--CREATE TABLE AS SELECT
--    procedura ma przyjmować 1 parametr typu varchar2, 
--którym będzie nazwa tabeli, którą chcemy zarchiwizować.
--    nazwa kopii archiwalnej tabeli ma być zbudowana wg 
--schematu nazwa_tabeli_oryginalnej_BKP
create or replace procedure BACKUP_TABLE(p_nazwa_tabeli varchar2)
is
begin
    execute immediate 'CREATE TABLE ' || p_nazwa_tabeli || '_BKP
                as select * from ' || p_nazwa_tabeli;
end;

begin
    BACKUP_TABLE('employees');
end;

select *
from employees_bkp;

drop table employees_bkp


-- 2. napisz procedurę check_consitency, której zadaniem będzie 
--sprawdzenie, czy tabela oraz jej archiwalna kopia, utworzona 
--przez procedurę z zadania 1, mają dokładnie tą samą zawartość.
--Procedura powinna drukować, przy pomocy DBMS_OUTPUT.PUT_LINE 
--informację TAK, jeśli obydwie tabele mają identyczną zawartość 
--oraz NIE w przeciwnym przypadku
--Procedura powinna przyjmować 1 parametr typu VARCHAR2, którym 
--byłaby nazwa oryginalnej tabeli
create or replace procedure check_consistency (p_nazwa_tabeli varchar2)
is
    var1 number(10);
    var2 number(10);
begin

execute immediate 'select count(*)
                    from (select * from ' || p_nazwa_tabeli
                            || ' minus 
                            select * from ' || p_nazwa_tabeli || '_bkp)' 
                    into var1;
execute immediate 'select count(*)
                    from (select * from ' || p_nazwa_tabeli || '_bkp 
                            minus 
                            select * from ' || p_nazwa_tabeli || ')' 
                    into var2;

    if var1 = 0 and var2 = 0 then
        dbms_output.put_line('TAK');
    else 
        dbms_output.put_line('NIE');
    end if;

end;


begin
    check_consistency('employees');
end;

-- drop table employees_bkp;
-- delete from employees_bkp
-- where employee_id = 100;

update employees_bkp
set last_name = 'XXX'
where employee_id = 100;


begin
    check_consistency('employees');
end;

-- minus



   
-- 3. napisz drugą wersję procedury check_consistency działającą w następujący sposób
--    Procedura powinna przyjmować 1 parametr typu VARCHAR2, którym byłaby nazwa oryginalnej tabeli
   
--    Powinna tworzyć pustą tabelę o nazwie ORYGINALNA_TABELA_LOG o strukturze tabeli oryginalnej, rozszerzoną o kolumnę INFO typu VARCHAR2(100)
--    W tabeli *_LOG powinien byc umieszczony każdy wiersz "różnicowy" - czyli taki, który istnieje TYLKO w tabeli oryginalnej lub TYLKO w tabeli _BKP
--    z dodatkową informacją zapisaną w kolumnie INFO
--    - jeśli wiersz istnieje TYLKO w tabeli oryginalnej - wtedy umieszczamy w kolumnie INFO dla tego wiersza napis 'ORIGINAL'
--    - jeśli wiersz istnieje TYLKO w tabeli _BKP - wtedy w kolumnie INFO dla tego wiersza umieszczaomy napis 'BACKUP'
   
create or replace procedure check_consistency_log (p_table_name varchar2)
is
begin
    execute immediate 'CREATE TABLE ' || p_table_name || '_LOG 
                as select * from ' || p_table_name || ' where 1=2';
    execute immediate 'ALTER TABLE ' || p_table_name || '_LOG
                add INFO varchar2(100)';
    execute immediate 'INSERT INTO ' || p_table_name || '_LOG
                    select a.*, ''ORIGINAL''
                    from (
                    select * from ' || p_table_name ||
                    ' minus select * from ' || p_table_name || '_BKP) a';
    execute immediate 'INSERT INTO ' || p_table_name || '_LOG
                    select a.*, ''BACKUP''
                    from (
                    select * from ' || p_table_name || 
                    '_BKP minus select * from ' || p_table_name || ') a';
end;

select e.*, salary*1.1 as new_salary
from employees e
;

begin
    check_consistency_log('employees');
end;

select *
from employees_log;
-- drop table employees_log