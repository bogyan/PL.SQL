-- wyjątki

-- Wyjątek jest to błąd WYKONANIA programu. Czyli sytuacja, w której program PL/SQL kompiluje się bez błędów, ale na skutek np. szczególnych wartości zmiennych próbuje WYKONAĆ niedozwoloną
-- operację taką, jak np. dzielenie przez zero

-- PL/SQL oferuje skuteczną metodę oprogramowywania sytuacji wyjątkowych - w ten sposób unikamy konieczności implementacji wielokrotnie zagnieżdżonych instrukcji
-- warunkowych



-- PL/SQL definiuje 3 typy wyjątków

-- 1. wyjątki predefiniowane
--    jest to wyjątek, który:
--    - posiada predefiniowany, wbudowany w maszynę PL/SQL identyfikator (podobnie do identyfikatora kursora niejawnego SQL)
--    - jest związany z konkretnym numerem błędu Oracle
--    przykłady:
-- 	NO_DATA_FOUND ORA-01403: polecenie SELECT INTO nie zwróciło żadnego wiersza
--         TOO_MANY_ROWS ORA-01422: polecenie SELECT INTO zwróciło więcej, niż jeden wiersz
--         ZERO_DIVIDE ORA-01476

--    pełna lista: https://docs.oracle.com/cd/B10501_01/appdev.920/a96624/07_errs.htm

--    obsługa takich wyjątków sprowadza się do ich oprogramowania w sekcji obsługi wyjątków bloku PL/SQL 

-- 2. wyjątki niepredefiniowane
--    jest to wyjątek, który
--    - nie posiada predefiniowanego identyfikatora
--    - jest konkretnym numerem błędu Oracle
--    przykład:
--    -60 : deadlock detected, while waiting on resource

-- 			Co to Deadlock?

-- 				np. transakcja A może blokować niektóre wiersze w tabeli Accounts, aby zaktualizować wybrane wiersze w tabeli Orders. 
-- 				Transakcja B blokuje te same wiersze w tabeli Orders, bo chce zaktualizować wiersze w tabeli Accounts, które jednocześnie są trzymane przez Transakcję A. 
-- 				Transakcja A nie może się zakończyć z powodu blokady Orders. Transakcja B nie może się zakończyć z powodu blokady Accounts. 
-- 				Polecenia nie wykonują się, chyba że DBMS wykryje deadlock i przerwie jedną z transakcji.

-- 			  https://docs.oracle.com/javadb/10.6.2.1/devguide/cdevconcepts28436.html
			  
--    obsługa takich błędów polega na
--    1) zadeklarowaniu jego identyfikatora (w sekcji deklaracji zmiennych)
--      składnia:
--      nazwa_wyjątku exception

--    2) związaniu go z konkretnym numerem błędu Oracle (również w sekcji deklaracji zmiennych)
--      składnia
--      PRAGMA_EXCEPTION_INIT(identyfikator,numer_błędu_oracle);

--    3) obsługi - w sekcji wykonywalnej (o tym za chwilę)

--   przykład:

  create or replace procedure update_data
  is
     deadlock_detected exception;
     pragma_exception_init(deadlock_detected,-60);
  begin
  ...
  end;
  /

  
-- 3. Wyjątki zdefiniowane przez programistę
--    Są to sytuacje, które z punktu widzenia Oracle NIE SĄ BłĘDAMI, ale są nimi z punktu widzenia logiki aplikacji np. próba ustawienia pracownikowi pensji na wartość poniżej zera
   
--    Obsługa takich wyjątków polega na
--    1) zadeklarowaniu identyfikatora (w sekcji deklaracji zmiennych)
--    2) w sekcji wykonywalnej - wywołanie instrukcji RAISE
--      składnia
--         RAISE identyfikator_wyjątku;
--    3) obsługa wyjątku --    - w sekcji obsługi wyjątków - obsłużenie wyjątku

--    przykład:

   create or replace procedure update_salary(p_emp_id number, p_new_sal number)
   is
       salary_lower_than_zero exception;
   begin
       if p_new_sal < 0 then
          raise salary_lower_than_zero;
       end if;
       ...
   end;



-- OBSŁUGA WYJĄTKÓW
-- 1. sekcja obsługi wyjątków
  
--    składnia
   begin
      .... // sekcja wykonywalna
   EXCEPTION
     WHEN id_wyjątku1 OR id_wyjątku2 OR ... OR id_wyjątkuN THEN
        kod obsługujący wyjątek
     WHEN id_wyjatkuN+1 OR ... THEN
        kod_obsługujący wyjątek
    [WHEN OTHERS THEN]
        kod obsługujący wszystkie pozostałe wyjątki
  end;



--   przykład
  
   create or replace procedure update_salary(p_emp_id number, p_new_sal number)
   is
       salary_lower_than_zero exception; --wyjatek zdef. przez programiste
       deadlock_detected exception;
       pragma exception_init(deadlock_detected,-60); --łączymy z błędem ORA-...60
       v_current_sal number(10);
       v_new_sal     number(10);
   begin
       if p_new_sal < 0 then
          raise salary_lower_than_zero;
       end if;

       select salary into v_current_sal       -- tutaj mogą wystąpić błędy TOO_MANY_ROWS lub NO_DATA_FOUND
       from employees
       where employee_id = p_emp_id;
       
       if p_new_sal < v_current_sal then -- jeżeli nowa pensja jest mniejsza od starej, to zostawiamy starą
          v_new_sal := v_current_sal;
       else
          v_new_sal := p_new_sal;
       end if;

       update employees                       -- tutaj może wystąpić błąd -60 (deadlock)
       set salary = v_new_sal
       where employee_id = p_emp_id;

       commit;
    exception
       when salary_lower_than_zero then --zdefiniowany przez programiste (zdefiniować + powiedzieć kiedy + obłużyć)
            rollback;
            dbms_output.put_line('Salary lower than 0');
       when no_data_found or too_many_rows then --predefiniowanym -> tylko obsłużyć
            rollback;
            dbms_output.put_line('Wrong Employee id');

       when deadlock_detected then --niepredefiniowany -> zdefiniować/powiązac i obsłużyć
            rollback;
            dbms_output.put_line('Deadlock detected');

      when others then
         rollback;
         dbms_output.put_line('Other error has occurred');
    end;


begin
     update_salary(100, 2000); --pensja 2000 dla pracownika 100
end;

select *
from employees
where employee_id = 100
;


begin
     update_salary(100, -2000); --pensja minus 2000 dla pracownika 100 (błąd: salary_lower_than_zero)
end;


begin
     update_salary(999, 2000); --pensja 20000 dla pracownika 999 (błąd: nie ma takiego pracownika)
end;

--kolejne trzy polecenia puszczane po sobie
update employees
set salary = 20000
where employee_id = 100;

begin
     update_salary(100, power(10, 4)*3); --pensja 30 000 dla pracownika 100
end;

select *
from employees
where employee_id = 100;

begin
     update_salary(100, power(10, 6)*3); --pensja 3 000 000 dla pracownika 100 -> błąd, bo SALARY(8,2) -> maksymalnie 6 cyfr całkowitych
end;

describe employees
;

update employees
set salary = 24000
where employee_id = 100;



--  Funkcje SQLCODE i SQLERRM 
--  SQLCODE zwraca numer ostatniego błędu
--  SQLERRM zwraca komunikat o błędzie
--  procedura RAISE_APPLICATION_ERROR ( nr_bledu, komunikat )
 
  create or replace procedure update_salary_v2(p_emp_id number, p_new_sal number)
   is
       --salary_lower_than_zero exception; --zamiast tego raise_application_error
       deadlock_detected exception;
       pragma exception_init(deadlock_detected,-60);
       v_current_sal number(10);
       v_new_sal     number(10);
       v_sqlcode     number(10);
       v_sqlerrm     varchar2(100);
   begin
       if p_new_sal < 0 then
          raise_application_error(-20001,'Salary lower than 0');
       end if;

       select salary into v_current_sal       -- tutaj mogą wystąpić błędy TOO_MANY_ROWS lub NO_DATA_FOUND
       from employees
       where employee_id = p_emp_id;
       
       if p_new_sal < v_current_sal then
          v_new_sal := v_current_sal;
       else
          v_new_sal := p_new_sal;
       end if;

       update employees                       -- tutaj może wystąpić błąd -60 (deadlock)
       set salary = v_new_sal
       where employee_id = p_emp_id;

       commit;
    exception
       when no_data_found or too_many_rows then
            rollback;
            dbms_output.put_line('Wrong Employee id');

       when deadlock_detected then
            rollback;
            dbms_output.put_line('Deadlock detected');

      when others then
         v_sqlcode := sqlcode;
         v_sqlerrm := substr(sqlerrm,1,100);
         rollback;
         dbms_output.put_line(v_sqlcode||':'||v_sqlerrm);
    end;
 

begin
     update_salary_v2(100, 2000); --pensja 2000 dla pracownika 100
end;

select *
from employees
where employee_id = 100
;



begin
     update_salary_v2(100, -2000); --pensja minus 2000 dla pracownika 100 (raise_application_error)
end;


begin
     update_salary_v2(999, 2000); --pensja 20000 dla pracownika 999 (błąd: nie ma takiego pracownika)
end;

--kolejne trzy polecenia puszczane po sobie
update employees
set salary = 20000
where employee_id = 100;

begin
     update_salary_v2(100, power(10, 4)*3); --pensja 30 000 dla pracownika 100
end;

select *
from employees
where employee_id = 100;

begin
     update_salary_v2(100, power(10, 6)*3); --pensja 3 000 000 dla pracownika 100 -> błąd, bo SALARY(8,2) -> maksymalnie 6 cyfr całkowitych
end;








--dodać wyjątek do wczesniego kodu:
--jeżeli pensja jest mniejsza od aktualnej, to chce wycofać operacje i wydrkowac komunikat błędu "pensja mniejsza niż obecna"
  create or replace procedure update_salary_v3(p_emp_id number, p_new_sal number)
   is
       --salary_lower_than_zero exception; --zamiast tego raise_application_error
       pensja_mniejsza_niz_wczesniej exception;
       deadlock_detected exception;
       pragma exception_init(deadlock_detected,-60);
       v_current_sal number(10);
    --    v_new_sal     number(10);
       v_sqlcode     number(10);
       v_sqlerrm     varchar2(100);
   begin
       if p_new_sal < 0 then
          raise_application_error(-20001,'Salary lower than 0');
       end if;

       select salary into v_current_sal       -- tutaj mogą wystąpić błędy TOO_MANY_ROWS lub NO_DATA_FOUND
       from employees
       where employee_id = p_emp_id;
       
       if p_new_sal < v_current_sal then
          raise pensja_mniejsza_niz_wczesniej;
       end if;

       update employees                       -- tutaj może wystąpić błąd -60 (deadlock)
       set salary = p_new_sal
       where employee_id = p_emp_id;

       commit;
    exception
       when no_data_found or too_many_rows then
            rollback;
            dbms_output.put_line('Wrong Employee id');

       when deadlock_detected then
            rollback;
            dbms_output.put_line('Deadlock detected');
        
        when pensja_mniejsza_niz_wczesniej then
            rollback;
            dbms_output.put_line('pensja mniejsza niż obecna');

      when others then
         v_sqlcode := sqlcode;
         v_sqlerrm := substr(sqlerrm,1,100);
         rollback;
         dbms_output.put_line(v_sqlcode||':'||v_sqlerrm);
    end;
 

begin
     update_salary_v3(100, 2000); --pensja 2000 dla pracownika 100
end;

begin
     update_salary_v3(100, -2000); --pensja 2000 dla pracownika 100
end;

-- Gdy podczas wykonywania programu w danej instrukcji wystąpi błąd, następuje
-- a) skok do sekcji obsługi wyjątków
-- b) sprawdzenie, gdzie w tej sekcji jest obsługiwany dany wyjątek
-- c) wykonanie stosownej (i tylko tej) sekcji obsługi 
-- d) wyjście z programu BEZ BŁĘDU



-- Zadanie 1
--    napisz procedurę, której zadaniem będzie ustawienie nowej pensji pracownika
--       procedura ta ma przyjmować następujące parametry
--       a) P_LAST_NAME VARCHAR2 - nazwisko pracownika
--       b) P_NEW_SALARY NUMBER  - jego nową pensję
--       Procedura ma obsługiwać następujące sytuacje wyjątkowe
--       - NEW_SAL_TOO_LOW - jesli nowa pensja jest mniejsza od starej - wyjątek zdefiniowany przez programistę
--                           w takiej sytuacji procedura ma drukować komunikat Nowa pensja mniejsza od starej oraz wycofywać transakcję
--       - NO_DATA_FOUND   - jeśli pracownik o zadanym nazwisku nie istnieje
--                           w takiej sytuacji procedura ma drukować komunikat 'Nieistniejący pracownik' oraz wycofywać transakcję

create or replace procedure nowa_pensja5000 (p_last_name varchar2, p_new_salary number)
is
    NEW_SAL_TOO_LOW exception;
    old_salary number(10);
begin

    select salary into old_salary
    from employees
    where last_name = p_last_name;

    IF p_new_salary < old_salary then
        raise NEW_SAL_TOO_LOW;
    end if;

    update employees
    set salary = p_new_salary
    where last_name = p_last_name;

    commit;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        rollback;
        dbms_output.put_line('Nieistniejący pracownik');
    WHEN NEW_SAL_TOO_LOW THEN
        rollback;
        dbms_output.put_line('Nowa pensja mniejsza od starej');
end;


begin
    nowa_pensja5000('King', 10000);
end;


begin
    nowa_pensja5000('Kowalski', 10000);
end;


begin
    nowa_pensja5000('King', 24000);
end;


-- Zadanie 2
--      Uzupełnij kod pow. procedury o obsługę wyjątków
--      TOO_MANY_ROWS (wyjątek predefiniowany, jeśli istnieje więcej pracowników o podanym nazwisku)
--      NEW_SALARY_LOWER_THAN_100 (wyjątek zdefiniowany przez programistę, jeśli nowa pensja jest mniejsza, niż 100

create or replace procedure nowa_pensja5000 (p_last_name varchar2, p_new_salary number)
is
    NEW_SAL_TOO_LOW exception;
    NEW_SALARY_LOWER_THAN_100 exception;
    old_salary number(10);
begin

    IF p_new_salary < 100 then
        raise NEW_SALARY_LOWER_THAN_100;
    end if;

    select salary into old_salary
    from employees
    where last_name = p_last_name;

    IF p_new_salary < old_salary then
        raise NEW_SAL_TOO_LOW;
    end if;

    update employees
    set salary = p_new_salary
    where last_name = p_last_name;

    commit;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        rollback;
        dbms_output.put_line('Nieistniejący pracownik');
    WHEN NEW_SAL_TOO_LOW THEN
        rollback;
        dbms_output.put_line('Nowa pensja mniejsza od starej');
    WHEN TOO_MANY_ROWS THEN
        rollback;
        dbms_output.put_line('Wielu pracownikow o tym samym nazwisku');
    WHEN NEW_SALARY_LOWER_THAN_100 THEn
        rollback;
        dbms_output.put_line('Nowa pensja mniejsza niz 100');
    
end;


begin
    nowa_pensja5000('Hunold', -5000);
end;