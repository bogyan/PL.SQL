-- TEMATY NA DZISIAJ:
-- 1. transakcje autonomiczne
-- 2. bufor wynikowy funkcji
-- 3. funkcje wołane w schemacie wołającego/właściciela


-- 1. transakcje autonomiczne
-- Transakcja autonomiczna jest to transakcja realizowana poza zewnętrznym kontekstem transakcyjnym
-- Oznacza to, że można ją zatwierdzić (commit) bądź wycofać (rollback) i operacja taka nie ma wpływu na "zewnętrzną" transakcję
-- Transakcje autonomiczne można realizować w dowolnych programach PL/SQL, wliczając w to np. wyzwalacze DML
-- Transakcje te mają zastosowanie np. w audytowaniu operacji wykonywanych przez użytkowników

-- Aby utworzyć program realizujący transakcję autonomiczną należy w sekcji deklaracji zmiennych umieścić dyrektywę kompilatora
-- PRAGMA AUTONOMOUS_TRANSACTION

-- przykład w wyzwalaczu realizującym operację DELETE na tabeli DEPARTMENTS

drop table log_table;

create table log_table
(operation varchar2(100),
 username  varchar2(100),
 operation_date date);


create or replace trigger tr_bef_delete_depts
before delete on departments
declare
	pragma autonomous_transaction;
begin
        insert into log_table(operation,username,operation_date)
        values ('delete on departments',nvl(v('APP_USER'),user),sysdate); --v('APP_UER') odpowiednik SELECT USER FROM dual;
        commit;
end;

select *
from log_table
;

delete from departments
where department_name = 'HR'
;


-- 2. bufor wynikowy dla funkcji
-- Bufor wynikowy pozwala na zapamiętanie wyniku działania stosownej funkcji dla określonych wartości parametrów.
-- Dzięki temu ponowne wywołanie tej właśnie funkcji może odczytać wynik z bufora bez konieczności jej wykonywania.


-- Składnia
create or replace function ... return TYP result_cache [relies on (TABLE_NAME)]
is
...

-- kl. relies on TABLE_NAME pozwala na uzależnienie buforowania wyników od wykonanych w międzyczasie operacji na zadanej tabeli.

-- przykład:

create or replace function get_max_sal(p_deptno employees.department_id%type) 
                                        return employees.salary%type 
                                        result_cache relies_on (employees)
is
   v_max_sal employees.salary%type;
begin
   select max(salary)
   into v_max_sal
   from employees
   where department_id = p_deptno;
   
   return v_max_sal;
end;
/ 

DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
BEGIN
    v_start_time := SYSTIMESTAMP;
    
    dbms_output.put_line(get_max_sal(50));

    v_end_time := SYSTIMESTAMP;
        
    DBMS_OUTPUT.PUT_LINE('Czas rozpoczęcia: ' || TO_CHAR(v_start_time, 'YYYY-MM-DD HH24:MI:SS.FF'));
    DBMS_OUTPUT.PUT_LINE('Czas zakończenia: ' || TO_CHAR(v_end_time, 'YYYY-MM-DD HH24:MI:SS.FF'));
    DBMS_OUTPUT.PUT_LINE('Czas trwania: ' || (v_end_time - v_start_time));
END;

update employees --update czysci cache -> znowu czas dłuższy (za pierwszym razem)
set salary = salary 
;



-- 3. funkcje wykonywane w schemacie wołającego/właściciela
-- Domyślnie w PL/SQL wszystkie programy są wykonywane w schemacie ich właścicieli.
-- Oznacza to np. że jeśli w kodzie danej funkcji odwołujemy się do tabeli TABLE_NAME, bez podawania schematu, to funkcja ta zakłada, że owa tabela znajduje się w jej schemacie.
-- Zachowanie to można zmienić przy pomocy kl. AUTHID
-- składnia:

create or replace <typ_programu> [return wynik] AUTHID <DEFINER|CURRENT_USER>
is
...

-- Uwagi:
-- 1. jeśli tworzymy pakiet, to stosowna klauzula (AUTHID) może być podana na poziomie pakietu, a nie poszcz. podpgrogramów w nim zawartych
-- 2. domyślną wartością kl. AUTHID jest DEFINER - czyli program będzie wykonywany w schemacie właściciela

-- DEFINER 	 -> gdy użytkownik B odpali procedure należącą do A, usuniemy wiersze ze zbioru employees należącego do A
-- CURRENT_USER -> gdy użytkownik B odpali procedure należącą do A, usuniemy wiersze ze zbioru employees należącego do B (używamy tylko jego procedury, a nie zbioru)

-- przykład:
create or replace procedure delete_employee(p_emp_id employees.employee_id%type)
authid current_user
is
begin
   delete from employees
   where employee_id = p_emp_id;
   
   commit;
end;

create or replace procedure delete_employee_v2(p_emp_id employees.employee_id%type)
authid definer
is
begin
   delete from employees
   where employee_id = p_emp_id;
   
   commit;
end;

grant execute on delete_employee    to public; --uprawnienia do posługiwania się moją procedurą CURRENT_USER
grant execute on delete_employee_v2 to public; --uprawnienia do posługiwania się moją procedurą DEFINER

grant select on employees to public; --uprawnienia do odczytywania mojej tabeli

--usuwam warunek integralności EMP_MANAGER_FK, aby móc dalej działac
alter table employees
drop constraints EMP_MANAGER_FK;

--usuwam warunek integralności DEPT_MGR_FK, aby móc dalej działac
alter table departments
drop constraints DEPT_MGR_FK;

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
            --poniższe odpalamy na innym koncie
            alter table employees
            drop constraints EMP_MANAGER_FK;

            select *
            from PL_a843_plsql_s99.employees --czy właściciel procedury ma pracownika X
            where employee_id = 124;

            select *
            from employees --czy ja mam pracownika X
            where employee_id = 124;

            --usuwamy pracownika X
            begin
                PL_a843_plsql_s99.delete_employee(124);
            end;


            --komu został skasowany pracownik 102? PL_a843_plsql_s99 czy mi?
            --ODPOWIEDŹ: mi, bo procedura delete_employee ma "authid current_user"
            select *
            from PL_a843_plsql_s99.employees
            where employee_id = 102;

            select *
            from employees
            where employee_id = 102;



            --usuwamy pracownika X przy pomocy _v2
            begin
                PL_a843_plsql_s99.delete_employee_v2(102);
            end;


            --komu został skasowany pracownik 102? PL_a843_plsql_s99 czy mi?
            --ODPOWIEDŹ: PL_a843_plsql_s99, bo procedura delete_employee ma "authid definer"
            select *
            from PL_a843_plsql_s99.employees
            where employee_id = 102;

            select *
            from employees
            where employee_id = 102;
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

-- zadania:

-- 1. Utwórz tabelę LOG_DML_OPERATIONS następującym poleceniem:
-- drop table log_dml_operations;
   create table log_dml_operations
   ( timestamp date,
     username   varchar2(30),
     tablename  varchar2(30),
     operation  varchar2(30) );
--     a następnie utwórz wyzwalacz związany z operacjami DML na tabeli EMPLOYEES, który
--    - będzie wyzwalaczem AFTER dla każdej operacji 
--    - będzie wyzwalaczem poleceniowym, a nie wierszowym
--    - celem nieodwracalnego zapisu do tabeli LOG_DML_OPERATIONS będzie wykorzystywał transakcje autonomiczne
--    - do tabeli utworzonej w kroku 1 będzie zapisywał informację o wykonanej operacji
--    - wyzwalacz powinien zatwierdzać transakcję

create or replace trigger trigger_dml_emp
    before update or delete or insert on employees
declare
    pragma autonomous_transaction;
begin
    if updating then
        insert into log_dml_operations(timestamp, username, tablename, operation)
            values (sysdate, nvl(v('APP_USER'), user), 'employees', 'update');
            commit;
    elsif inserting then
        insert into log_dml_operations(timestamp, username, tablename, operation)
            values (sysdate, nvl(v('APP_USER'), user), 'employees', 'insert');
            commit;
    else 
        insert into log_dml_operations(timestamp, username, tablename, operation)
        values (sysdate, nvl(v('APP_USER'), user), 'employees', 'delete');
        commit;
    end if;
end;

select *
from log_dml_operations;

delete from employees
where last_name = 'Kowalski';

update employees
set salary = salary;


select 




-- 2. utwórz funkcję, posługującą się buforem wynikowym.
--    Jej celem będzie zwrócenie liczby wierszy z iloczynu kartezjańskiego EMPLOYEES x EMPLOYEES x EMPLOYEES x EMPLOYEES x EMPLOYEES x EMPLOYEES
--    Buforowanie wyniku będzie zależało od tabeli EMPLOYEES
--    Kilkukrotnie wykonaj ową funkcję, mierząc czasy wykonań
create or replace function liczba_pracownikow return number result_cache relies_on (employees)
is
    l_prac number(10);
begin
    select count(*) into l_prac
    from employees, employees, employees, employees, employees;

    return l_prac;

end;

select power(38, 5) --79235168
from dual;

begin 
    dbms_output.put_line(to_char(sysdate, 'hh24:mi:ss'));
    dbms_output.put_line(liczba_pracownikow);
    dbms_output.put_line(to_char(sysdate, 'hh24:mi:ss'));
end;

update employees
set salary = salary;