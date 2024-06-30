-- Tematy: Kursor niejawny SQL, kursory jawne, kursory sparametryzowane, pętle kursorowe, kl. WHERE CURRENT OF, kl. FOR UPDATE, kursory anonimowe

-- Kursor - obszar pamięci SZBD w którym przechowywane są informacje związane z wykonaniem poj. polecenia SQL

-- Kursorami w PL/SQL możemy posługiwać się poprzez odwołanie do ich nazw oraz atrybutów

-- 1. Kursor niejawny SQL
--    Kursor niejawny SQL (SQL to jego indetnyfikator/nazwa) jest to predefiniowany identyfikator, istniejący w każdym programie PL/SQL (tworzony automatycznie w chwili uruchamiania tego programu)
--    w którym przechowywane są informacje dot. ostatnio wykonanego lub będącego w trakcie wykonywania w tym programie polecenia SQL.
--    - liczba wierszy przetworzonych przez owo polecenie: atrybut SQL%ROWCOUNT
--    - czy w ogóle jakikolwiek wiersz został przetworzony: 
--    	atrybut SQL%NOTFOUND (zwraca TRUE jeśli ostatnio wykonane polecenie SQL nie przetworzyło żadnego wiersza)
--    	atrybut SQL%FOUND (zwraca TRUE jeśli ostatnio wykonane polecenie SQL przetworzyło przynajmniej 1 wiersz)
   	
--    przykład zastosowania:
--    funkcja, której celem jest zwiększenie pensji pracowników zatrudnionych w zadanym departamencie, funkcja ma zwracać liczbę pracowników, którzy dostali podwyżkę
   
   create or replace function increase_salary 
                ( p_department_id number, p_increase number) return number
   is
   begin
      update employees
      set salary = salary + p_increase
      where department_id = p_department_id;
      
      return SQL%ROWCOUNT;
   end;
   
begin
    dbms_output.put_line(increase_salary(20, 500));
end;

 
-- 2. kursory jawne
--    Kursor jawny pozwala na krokowe (wiersz po wierszu) przetwarzanie polecenia SQL 
--    Aby móc go stosować, należy
--    a) zadeklarować i związać z poleceniem SELECT - sekcja deklaracji zmiennych
--       przykład:
      
-- r_emp employees%rowtype

      create or replace function get_sum_salary return number
      is
         CURSOR c_emp IS select * from employees;
         r_emp c_emp%rowtype; -- zwróćmy uwagę na atrybut ROWTYPE - może być stosowany do deklaracji zmiennych rekordowych o strukturze kursora
         v_sum_salary number(10) := 0;
      begin
          ....
      end;
      
--    b) otworzyć - w sekcji wykonywalnej
      create or replace function get_sum_salary return number
      is
         CURSOR c_emp IS select * from employees;
         r_emp c_emp%rowtype; -- zwróćmy uwagę na atrybut ROWTYPE - może być stosowany do deklaracji zmiennych rekordowych o strukturze kursora
         v_sum_salary number(10) := 0;
      begin
          OPEN c_emp;
          ...
      end;
      
--   c) pobierać wiersze - w części wykonywalnej:
  
      create or replace function get_sum_salary return number
      is
         CURSOR c_emp IS select * from employees;
         r_emp c_emp%rowtype; -- zwróćmy uwagę na atrybut ROWTYPE - może być stosowany do deklaracji zmiennych rekordowych o strukturze kursora
         v_sum_salary number(10) := 0;
      begin
          OPEN c_emp;
          FETCH c_emp INTO r_emp;
          ...
      end;  
      
    --   UWAGA:
    --   a) tuż po otwarciu kursora wskaźnik jego położenia ustawia się automatycznie na pierwszym wierszu. 
    -- Instrukcja FETCH automatycznie przesuwa kursor do następnego wiersza.
    --   b) Najczęściej wiersze z kursora pobierane są w pętlach:
      
      create or replace function get_sum_salary return number
      is
         CURSOR c_emp IS select * from employees;
         r_emp c_emp%rowtype; -- zwróćmy uwagę na atrybut ROWTYPE - może być stosowany do deklaracji zmiennych rekordowych o strukturze kursora
         v_sum_salary number(10) := 0;
      begin
          OPEN c_emp;
          LOOP
          	FETCH c_emp INTO r_emp;
          	EXIT when c_emp%NOTFOUND;
          	v_sum_salary := v_sum_salary + r_emp.salary;          	
          END LOOP;
          ...
      end;          

    --   loop

    --   i := i + 1 

    --   UWAGI
    --   *) w pętli podstawowej LOOP...END LOOP instrukcja EXIT musi być podana, inaczej pętla takowa staje się nieskończona
    --   *) aby wyjść z pętli wtedy, gdy pobierzemy wszystkie wiersze, należy posłużyć się atrybutem %NOTFOUND - tak, jak w pow. przykładzie
      
--    d) zamknąć kursor - w części wykonywalnej:
      create or replace function get_sum_salary return number
      is
         CURSOR c_emp IS select * from employees;
         r_emp c_emp%rowtype; -- zwróćmy uwagę na atrybut ROWTYPE - może być stosowany do deklaracji zmiennych rekordowych o strukturze kursora
         v_sum_salary number(10) := 0;
      begin
          OPEN c_emp;
          LOOP
          	FETCH c_emp INTO r_emp;
          	EXIT when c_emp%NOTFOUND;
          	v_sum_salary := v_sum_salary + r_emp.salary;          	
          END LOOP;
          CLOSE c_emp;
          return v_sum_salary;
      end;  
      
begin
    dbms_output.put_line(get_sum_salary);
end;


-- 3. kursory sparametryzowane
--    Kursory, podobnie do procedur i funkcji można parametryzować.
--    Parametry kursora musimy zadeklarować w jego deklaracji:
   
      create or replace function get_sum_salary_v2(p_department_id number) return number
      is
         CURSOR c_emp(p_deptno number) IS select * from employees 
                                            where department_id = p_deptno;
         r_emp c_emp%rowtype; -- zwróćmy uwagę na atrybut ROWTYPE - może być stosowany do deklaracji zmiennych rekordowych o strukturze kursora
         v_sum_salary number(10) := 0;
      begin
	...
      end;   
      
    -- ich wartości ustawiamy podczas otwierania kursora:
       create or replace function get_sum_salary_v2(p_department_id number) return number
      is
         CURSOR c_emp(p_deptno number) IS select * from employees 
                                            where department_id = p_deptno;
         r_emp c_emp%rowtype; -- zwróćmy uwagę na atrybut ROWTYPE - może być stosowany do deklaracji zmiennych rekordowych o strukturze kursora
         v_sum_salary number(10) := 0;
      begin   
          OPEN c_emp(p_department_id);
          LOOP
          	FETCH c_emp INTO r_emp;
          	EXIT when c_emp%NOTFOUND;
          	v_sum_salary := v_sum_salary + r_emp.salary;          	
          END LOOP;
          CLOSE c_emp;
          return v_sum_salary;
      end;  
      
begin
    dbms_output.put_line(get_sum_salary_v2(90));
end;
      
-- 4. pętle kursorowe
--    Pętle kursorowe upraszczają i skracaja tworzenie programów PL/SQL wykorzystujących jawne kursory. Stosujemy je wtedy, gdy chcemy zawsze przetwarzać wszystkie
--    wiersze zwracane przez kursor
   
--    przykład (kursor bez parametrów):

      create or replace function get_sum_salary return number
      is
         CURSOR c_emp IS select * from employees;
         v_sum_salary number(10) := 0;
      begin   
          FOR r_emp IN c_emp LOOP                  -- niejawne otwarcie przy wejściu do pętli
          					   -- automatyczne tworzenie zmiennej r_emp przy wejściu do pętli
                                                   -- niejawny FETCH przy każdej iteracji
          	v_sum_salary := v_sum_salary + r_emp.salary;          	
          END LOOP;                                -- niejawne zamknięcie podczas wyjścia z pętli
          return v_sum_salary;
      end; 

begin
    dbms_output.put_line(get_sum_salary);
end;
--    przykład (kursor z parametrem p_deptno)   
      create or replace function get_sum_salary_v2(p_department_id number) return number
      is
         CURSOR c_emp(p_deptno number) IS select * from employees 
                                            where department_id = p_deptno;
         v_sum_salary number(10) := 0;
      begin   
          FOR r_emp IN c_emp(p_department_id) LOOP -- niejawne otwarcie przy wejściu do pętli
          					   -- automatyczne tworzenie zmiennej r_emp przy wejściu do pętli
                                                   -- niejawny FETCH przy każdej iteracji
          	v_sum_salary := v_sum_salary + r_emp.salary;          	
          END LOOP;                                -- niejawne zamknięcie podczas wyjścia z pętli
          return v_sum_salary;
      end; 

begin
    dbms_output.put_line(get_sum_salary_v2(10));
end;


-- 5. kl. FOR UPDATE
--    Kl. WHERE CURRENT OF nazwa_kursora
   
--    kl. FOR UPDATE polecenia SELECT nakłada blokadę wyłączną na wiersze przetwarzane przez to polecenie.
--    Blokady zdejmowane są automatycznie przy kończeniu transakcji (COMMIT lub ROLLBACK)
   
--    kl. ta może być również podana w definicji kursora, blokuje wtedy wiersze, które wchodzą w skład zbioru aktywnego
   
--    kl. WHERE CURRENT OF nazwa_kursora pozwala na modyfikację lub usunięcie wiersza aktualnie wskazywanego przez kursor (stosujemy ją jako warunek selekcji w poleceniach UPDATE lub DELETE)
   
--    przykład:
   create or replace procedure update_salary(p_department_id number, p_increase number)
   is
      cursor c_emp is select * from employees for update;
   begin
      for r_emp in c_emp loop
          if r_emp.department_id = p_department_id then
             update employees
                set salary = salary + p_increase
             where current of c_emp;
          end if;
      end loop;      
      commit;
   end;

begin
    update_salary(10, 500);
end;

select sum(salary)
from employees
where department_id = 10 --20
;

-- 6. kursory anonimowe
--    Kursory anonimowe nie są identyfikowane przez nazwę. Ułatwiają posługiwanie się kursorami w nawet jeszcze większym stopniu, niż pętle kursorowe.
--    Kursory takie nie wymagają deklaracji.
   
--    przykład:
      create or replace function get_sum_salary return number
      is
         v_sum_salary number(10) := 0;
      begin   
          FOR r_emp IN (select * from employees) loop
          	v_sum_salary := v_sum_salary + r_emp.salary;          	
          END LOOP;                                
          return v_sum_salary;
      end;    


      create or replace function get_sum_salary_v2(dep number) return number
      is
         v_sum_salary number(10) := 0;
      begin   
          FOR r_emp IN (select * from employees where department_id = dep) loop
          	v_sum_salary := v_sum_salary + r_emp.salary;          	
          END LOOP;                                
          return v_sum_salary;
      end;    


begin
    dbms_output.put_line(get_sum_salary_v2(10));
end;



-- zadania:

-- 1. napisz funkcję, której zadaniem będzie podwyższenie pensji o podany procent pracownikom zatrudnionym na podanym stanowisku.
--    Funkcja powinna zwracać liczbę pracowników, którzy otrzymali podwyżkę
--    Funkcja powinna przyjmować dwa parametry
--    a) p_job_id varchar2 - stanowisko pracy
--    b) p_percent number  - procent podwyżki

create or replace function podwyzka (p_job_id varchar2, p_percent number)
                                                        return number
is
begin
    update employees
    set salary = salary * (1 + p_percent/100)
    where job_id = p_job_id;

    return SQL%rowcount;
end;

begin
    dbms_output.put_line(podwyzka('ST_CLERK', 10));
end;
   
-- 2. napisz procedurę, której zadaniem będzie wydrukowanie nazwisk (wywołanie DBMS_OUTPUT.PUT_LINE) pracowników zatrudnionych w podanym departamencie
--    Procedura powinna przyjmować 1 parametr:
--    p_department_id number - nr departamentu z którego drukujemy nazwiska

--jak w pkt 6
create or replace procedure drukuj_nazwiska (p_department_id number)
is
begin
    FOR r_emp in (select last_name from employees 
                                where department_id = p_department_id) loop
        DBMS_OUTPUT.PUT_LINE(r_emp.last_name);
    end loop;
end;

begin
    drukuj_nazwiska(50);
end;

--jak w pkt 4
create or replace procedure drukuj_nazwiska (p_department_id number)
is
CURSOR c_emp(p_deptno number) IS select last_name from employees 
                                where department_id = p_deptno;
r_emp c_emp%rowtype;
begin
    FOR r_emp in c_emp(p_department_id) loop
        DBMS_OUTPUT.PUT_LINE(r_emp.last_name);
    end loop;
end;

begin
    drukuj_nazwiska(50);
end;


--jak w pkt 3
create or replace procedure drukuj_nazwiska (p_department_id number)
is
CURSOR c_emp(p_deptno number) IS select last_name from employees 
                                where department_id = p_deptno;
r_emp c_emp%rowtype;
begin
    OPEN c_emp(p_department_id);
    LOOP
        FETCH c_emp into r_emp;
        EXIT WHEN c_emp%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(r_emp.last_name);
    end loop;
    CLOSE c_emp;
end;


begin
    drukuj_nazwiska(50);
end;


select last_name
from employees
where last_name = 'Heiden'
;


-- 3. napisz procedurę, której zadaniem będzie wydrukowanie listy stanowisk 
-- pracy funkcjonujących w zadanym departamencie (DBMS_OUTPUT.PUT_LINE)
-- Procedura powinna przyjmować 1 parametr - numer departamentu, z którego chcemy wydrukować stanowiska
-- UWAGA: lista powinna zawierać wyłącznie unikalne nazwy stanowisk pracy

create or replace procedure drukuj_stanowiska(p_department_id number)
is
begin
    FOR r_emp in (select distinct job_title from employees
                                    join jobs using(job_id)
                                    where department_id = p_department_id) loop

        dbms_output.put_line(r_emp.job_title);
    end loop;
end;

begin
    drukuj_stanowiska(50);
end;

   
