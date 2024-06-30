-- Optymalizacja kodu PL/SQL

-- 1. Bulk Loads

--    klauzula BULK COLLECT   
--    pozwala na wykonywanie polecenia SELECT odczytującego wiele wierszy i podstawienie ich do tablicy PL/SQL lub nested table
   
--    składnia
   SELECT ...
   BULK COLLECT INTO tablica
   FROM ...
   ...
   
--    przykład:
   
   create or replace procedure print_all_departments
   is
   	type t_dept_table is table of departments%rowtype;
   	v_dept_table t_dept_table;
   begin
      select *
      bulk collect into v_dept_table
      from departments;
      
      for i in v_dept_table.first..v_dept_table.last loop
      	dbms_output.put_line ( v_dept_table(i).department_id||': '||v_dept_table(i).department_name);
      end loop;
   end;

   begin
        print_all_departments;
   end;
   
   
--    kl. FETCH ... BULK LOAD [LIMIT N]
--    kl. ta może być zastosowana w odniesieniu do kursorów. Pozwala na pobranie wszystkich, bądź N pierwszych (LIMIT N) wierszy z kursora
   
--    składnia
   FETCH cursor BULK COLLECT INTO tablica [LIMIT N]
   
--    przykład:
   create or replace procedure print_1st3_departments
   is
   	cursor c_dept is select * from departments order by department_id;
        type t_dept_table is table of c_dept%rowtype;
        v_dept_table t_dept_table;
   begin
      open c_dept;
         fetch c_dept bulk collect into v_dept_table limit 3;
      close c_dept;
      
      for i in v_dept_table.first..v_dept_table.last loop
      	dbms_output.put_line ( v_dept_table(i).department_id||': '||v_dept_table(i).department_name);
      end loop;
   end;
   
   begin
    print_1st3_departments;
   end;
   
--    instrukcja FORALL
   
--    W PL/SQL instrukcja FORALL jest używana do wydajnego przetwarzania masowego operacji DML 
--   (w pętli FOR każda operacja DML jest wykonywana oddzielnie, co spowalnia przetwarzanie).
   
--    składnia
    FORALL indeks IN tablica.first..tablica.last
    	instrukcja_DML;
    
    
    -- Uwagi:
    
    -- FORALL NIE JEST PĘTLĄ. Jest instrukcją PL/SQL, która pozwala na wsadowe, jednoczesne wykonanie instrukcji wewnątrz FORALL dla wszystkich elementów tablicy
    
    -- przykład:
    
    create or replace procedure update_salaries
    is
        type t_emp_table is table of employees%rowtype;
        v_emp_table t_emp_table;
    begin
        select *
        bulk collect into v_emp_table
        from employees;
        
        for i in v_emp_table.first..v_emp_table.last loop
        	v_emp_table(i).salary := v_emp_table(i).salary + 100;
        end loop;
        
        forall i in v_emp_table.first..v_emp_table.last
        	update employees
        	set salary = v_emp_table(i).salary
        	where employee_id = v_emp_table(i).employee_id;
     end;

select avg(salary) from employees;

     begin
        update_salaries;
     end;



    -- przykład2:

    create table emp_copy as 
    select *
    from employees
    where 1=2;

    create or replace procedure copy_employees
    is
        type t_emp_table is table of employees%rowtype;
        v_emp_table t_emp_table;
    begin
        select *
        bulk collect into v_emp_table
        from employees;

        
        forall i in v_emp_table.first..v_emp_table.last
		insert into emp_copy values v_emp_table(i);
     end;
    
    begin
        copy_employees;
    end;

    select *
    from emp_copy
    ;

-- 2. Funkcje potokowe i tabelaryczne

--    Funkcje tabelaryczne zwracają tabelę wartości, która może być traktowana jako wirtualna tabela w kl. FROM polecenia SELECT, przy użyciu operatora rzutowania TABLE()
--    składnia wykorzystania
   
   SELECT ...
   FROM TABLE(wywołanie_funkcji)
   ...
   
--    klasyczne przetwarzanie niepotokowe w bazie danych
--    1. zamiast funkcji tabelarycznej procedura przeliczająca dane i zapisująca je w "staging tables"
--    2. polecenie SELECT zamiast czytać dane "z funkcji", czyta je z owej tabeli pośredniej
   
    -- Funkcje potoke umożliwia przetwarzanie dużych zbiorów danych bardziej efektywnie: zamiast zwracać wszystkie wyniki na raz, funkcje potokowe zwracają wyniki kawałek po kawałku.
    -- Dzięki przetwarzaniu danych w sposób iteracyjny (potokowy), funkcje te mogą zacząć zwracać wyniki od razu, bez czekania na zakończenie całego przetwarzania. 
    -- Minimalizuje to użycie pamięci i umożliwia rozpoczęcie pracy na wynikach wcześniej.
  
--    Składnia:
   create or replace function .... 
   PIPELINED  --deklaracja oznaczająca, że funkcja jest funkcją potokową
   is
   ...
   PIPE ROW (zwracana wartość); --zamiast tradycyjnego RETURN. PIPE ROW zwracać będzie pojedynczą wartość gotową do przetworzenia w kolejnym etapie, będzie więc wywoływana wielokrotnie.


--    Przykład:

   create or replace package pkg_types
   is
       type t_emp_table is table of employees%rowtype;
   end; 

   create or replace function get_emps return pkg_types.t_emp_table
   pipelined
   is
   begin
      for r in (select * from employees) loop
      	pipe row (r);
      end loop;
   end;
   
   select * from table(get_emps);

-- 3. Zrównoleglanie wykonywania kodu PL/SQL
--    Funkcje tabelaryczne można zrównoleglać
--    Służy do tego klauzula PARALLEL_ENABLE
   
--    1. potokowe
--    2. w ramach pojedynczego etapu
   
--    przykład:
   
   create or replace function get_emps_v2 return pkg_types.t_emp_table
   pipelined
   parallel_enable
   is
   begin
      for r in (select * from employees) loop
      	pipe row (r);
      end loop;
   end;

    select * from table(get_emps_v2);

   
-- Zadania
-- 1. napisz następującą funkcję potokową, którą można zrównoleglać
--    funkcja ma przyjmować parametr p_grade_level typu JOB_GRADES.GRADE_LEVEL
--    jej zadaniem będzie odczytywanie pracowników z tabeli EMPLOYEES, którzy mieszczą się w zadanej stawce i zwrócenie ich danych na zewnątrz.
   
--    wskazówka:
--    w pierwszym kroku należy utworzyć pakiet PL/SQL, w którym zostanie zadeklarowany stosowny typ tablicowy, umożliwiający zadeklarowanie wyniku funkcji

create or replace package pakiet_tabela
is
    type t_emp is table of employees%rowtype;
end;

create or replace function czytaj_emp(p_grade_level job_grades.grade_level%type) 
                                                                            return pakiet_tabela.t_emp
    pipelined
    parallel_enable
is
begin
    for r in (select e.*
                from employees e, job_grades
                where salary between lowest_sal and highest_sal
                    and grade_level = p_grade_level) loop
        pipe row(r);
    end loop;
end;

select *
from table(czytaj_emp('B'))
;



-- 2. napisz procedurę przeliczającą pensje pracowników 
--    procedura powinna odczytywać do stosownej tablicy dane pracowników posortowane wg. daty zatrudnienia pracownika i identyfikatora pracownika
--    przeliczenia powinny być realizowane w owej tablicy na podstawie następujących reguł
--    jeśli pracownik jest najwcześniej zatrudnionym pracownikiem, to podwyżka powinna wynosić 10%
--    dla pozostałych pracowników podwyżka powinna wynosić 5%
--    Po wykonaniu przeliczeń, przy pomocy konstrukcji FORALL zaktualizuj wszystkie pensje w tabeli EMPLOYEES wynikami obliczeń umieszczonymi w zmiennej tablicowej
create or replace procedure przelicz_pensje_pracownikow 
is
    type t_tab is table of employees%rowtype;
    v_tab t_tab;
begin
    select * bulk collect into v_tab
    from employees
    order by hire_date, employee_id;

    FOR i in v_tab.first..v_tab.last loop
        if i = 1 then
            v_tab(i).salary := v_tab(i).salary * 1.1;
        else
            v_tab(i).salary := v_tab(i).salary * 1.05;
        end if;
    end loop;

    FORALL i in v_tab.first..v_tab.last
        update employees
        set salary = v_tab(i).salary
        where employee_id = v_tab(i).employee_id;

end;

select avg(salary) from employees;

begin
    przelicz_pensje_pracownikow;
end;