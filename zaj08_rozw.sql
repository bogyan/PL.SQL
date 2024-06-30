-- 1. napisz procedurę, której zadaniem będzie wstawianie danych nowego pracownika do tabeli EMPLOYEES
--    Procedura ma przyjmować następujące parametry
--    p_last_name - nazwisko
--    p_first_name - imię
--    p_job_id     - stanowisko pracy
--    p_department_id - numer departamentu
   
--    procedura, przed wstawianiem pow. danych ma 
--    - ustalać datę zatrudnienia na bieżącą datę systemową
--    - ustalać pensję pracownika na najniższą pensję na danym stanowisku w całej firmie
--    - ustalać id przełożonego danego pracownika - powinien być nim kierownik danego departamentu (kol. manager_id w tabeli DEPARTMENTS)
--    - jeśli stanowisko danego pracownika to SA_REP, to jego commission_pct oraz bonus powinny być również ustalane na najniższe wartości w stosownych kolumnach w całej tabeli EMPLOYEES
--    - jeśli stanowisko pracy owego pracownika to SA_MAN, to procedura nie powinna wstawiać wiersza, a zamiast tego winna generować wyjątek zdefiniowany przez programistę TOO_MANY_SA_MANAGERS
--    - wartość dla kolumny EMAIL powinna być konstruowana wg schemau pierwszaliteraimienia||nazwisko skonwertowana do dużych liter
--    - numer pracowniczy na maksymalną wartość employee_id + 1
   
   
create or replace procedure ins_new_emp(p_last_name varchar2, p_first_name varchar2, p_job_id varchar2, p_department_id number)
is

    min_salary employees.salary%type;
    new_manager_id departments.manager_id%type;
    new_commission_pct employees.commission_pct%type;
    new_bonus employees.bonus%type;
    TOO_MANY_SA_MANAGERS EXCEPTION;
    new_employee_id employees.employee_id%type;

begin

    if p_job_id = 'SA_MAN' then
        raise TOO_MANY_SA_MANAGERS;
    end if;

    select min(salary) into min_salary
    from employees
    where job_id = p_job_id
    ;

    select manager_id into new_manager_id
    from departments
    where department_id = p_department_id 
    ;
    
    if p_job_id = 'SA_REP' then
        select min(commission_pct), min(bonus) into new_commission_pct, new_bonus 
        from employees;
    end if;

    select max(employee_id) + 1 into new_employee_id 
    from employees;

    insert into employees (last_name, first_name, job_id, department_id, hire_date, salary, manager_id, commission_pct, email, employee_id) 
                                 values (p_last_name, p_first_name, p_job_id, p_department_id, sysdate, min_salary, new_manager_id, new_commission_pct
                                               , upper(substr(p_first_name, 1, 1) || p_last_name), new_employee_id);

EXCEPTION
    when TOO_MANY_SA_MANAGERS then
    dbms_output.put_line('zbyt dużo SA_MAN!');

commit;

end;

begin 
ins_new_emp('Paska', 'Norbert', 'SA_REP', 50);
end;

select *
from employees
where last_name = 'Paska'
;


delete from employees
where last_name = 'Paska';



   
-- 2. napisz procedurę, której zadaniem będzie zmiana pensji pracowników na zadanym stanowisku pracy
--    procedura powinna przyjmować dwa parametry
--    p_job_id - id stanowiska pracy
--    p_amount - kwota podwyżki
   
--    procedura nie powinna dopuszczać do sytuacji, w której nowa pensja byłaby większa od starej o więcej, niż 25 %
   
--       wskazówka: postaraj się wykorzystać kursory
   
--    procedura powinna zwracać w następujących parametrach wyjściowych
--    p_number_accepted - liczba pracowników, u których zmiana pensji się powiodła
--    p_number_rejected - liczba pracowników, u których zmiana pensji się nie powiodła ze względu na przedstawione pow. ograniczenie
   

create or replace procedure salary_change (p_job_id IN varchar2, p_amount IN number, p_number_accepted OUT number, p_number_rejected OUT number)
is
    CURSOR c_emp IS select * from employees where job_id = p_job_id for update;
    v_accepted number(5) := 0;
    v_rejected number(5) := 0;

begin
    for r_emp in c_emp loop
    
    if p_amount / r_emp.salary < 1.25 then
    
        v_accepted := v_accepted + 1;   
        update employees
        set salary = salary + p_amount
        where current of c_emp;
    
    else
    
        v_rejected := v_rejected + 1;
    
    end if;
    
    end loop;
    
    p_number_accepted := v_accepted;
    p_number_rejected := v_rejected;

end;

declare
    accept number;
    reject number;
begin 
    salary_change('AD_PRES', 1, accept, reject );
    dbms_output.put_line('accepted: ' || accept || ' rejected: ' || reject);
end;

   
   
-- 3. napisz procedurę, która poprzez wywoływanie procedury PUT_LINE z pakietu DBMS_OUTPUT drukować będzie nazwiska, imiona i pensję N najlepiej 
--    zarabiających pracowników na poszcz. stanowiskach pracy
--    procedura powinna przyjmować jeden parametr: N - liczbę owych najlepiej zarabiających pracowników do wydrukowania
   
create or replace procedure best_payroll (N number)
is
    CURSOR c_job_id IS select distinct job_id from employees;
    CURSOR c_emp(p_job_id varchar2) IS select *
                                          from employees
                                          where job_id = p_job_id
                                          order by salary desc;
    v_job_id employees.job_id%type;
begin

    for r_job_id in c_job_id loop
        v_job_id := r_job_id.job_id;
        
        for r_emp in c_emp(v_job_id) loop
            if c_emp%rowcount <= n then
            dbms_output.put_line(r_emp.last_name || ' ' || r_emp.first_name ||  ' ' || r_emp.salary);
            end if;
        
        end loop;
    
    end loop;

end;

begin 
    best_payroll(3);
end;
  
  
-- 4. napisz funkcję, której zadaniem będzie zwrócenie miejsca pracownika na liście rankingowej najlepiej zarabiających
--    funkcja ma przyjmować 1 parametr: p_employee_id
   
create or replace function salary_ranking (p_employee_id number) return number
is
    CURSOR c_emp IS select * from employees order by salary desc;
    ranking number(10) := 0;

begin

    for r_emp in c_emp loop

        ranking := ranking + 1;

        if r_emp.employee_id = p_employee_id then
            return ranking;
        end if;
    
    end loop;

end;

begin
    dbms_output.put_line(salary_ranking(104));
end;


  

-- 5. zmodyfikuj funkcję z zad. 4, tak, aby zwracała miejsce pracownika na liście najlepiej zarabiających 
-- w departamencie, w którym dany pracownik jest zatrudniony

create or replace function salary_ranking_dep  (p_employee_id number) return number
is
    CURSOR c_emp(pc_department_id number) IS select * from employees where department_id = pc_department_id order by salary desc;
    ranking number(10) := 0;
    dep_num employees.department_id%type;

begin

    select department_id into dep_num 
    from employees
    where employee_id = p_employee_id;

    for r_emp in c_emp(dep_num) loop

        ranking := ranking + 1;

        if r_emp.employee_id = p_employee_id then
            return ranking;
        end if;
    
    end loop;

end;
              

begin
    dbms_output.put_line(salary_ranking_dep(104));
end;
 


-- 6. napisz pakiet PL/SQL, który grupować będzie wszystkie powyższe procedury i funkcje
-- napisz przeciążoną wersję funkcji salary_raning, która będzie miała parametr p_last_name zamiast p_employee_id

create or replace package zajecia8
is

        procedure ins_new_emp(p_last_name varchar2, p_first_name varchar2, p_job_id varchar2, p_department_id number);
        procedure salary_change (p_job_id IN varchar2, p_amount IN number, p_number_accepted OUT number, p_number_rejected OUT number);           
        procedure best_payroll (N number);
         
        function salary_ranking (p_employee_id number) return number;
        function salary_ranking_dep  (p_employee_id number) return number;
        function salary_ranking (p_last_name varchar2) return number;


end;
/

create or replace package body zajecia8
is
--begin

        procedure ins_new_emp(p_last_name varchar2, p_first_name varchar2, p_job_id varchar2, p_department_id number)
        is
        
            min_salary employees.salary%type;
            new_manager_id departments.manager_id%type;
            new_commission_pct employees.commission_pct%type;
            new_bonus employees.bonus%type;
            TOO_MANY_SA_MANAGERS EXCEPTION;
            new_employee_id employees.employee_id%type;
        
        begin
        
            if p_job_id = 'SA_MAN' then
                raise TOO_MANY_SA_MANAGERS;
            end if;
        
            select min(salary) into min_salary
            from employees
            where job_id = p_job_id
            ;
        
            select manager_id into new_manager_id
            from departments
            where department_id = p_department_id 
            ;
            
            if p_job_id = 'SA_REP' then
                select min(commission_pct), min(bonus) into new_commission_pct, new_bonus 
                from employees;
            end if;
        
            select max(employee_id) + 1 into new_employee_id 
            from employees;
        
            insert into employees (last_name, first_name, job_id, department_id, hire_date, salary, manager_id, commission_pct, email, employee_id) 
                                         values (p_last_name, p_first_name, p_job_id, p_department_id, sysdate, min_salary, new_manager_id, new_commission_pct
                                                       , upper(substr(p_first_name, 1, 1) || p_last_name), new_employee_id);
        
        EXCEPTION
            when TOO_MANY_SA_MANAGERS then
            dbms_output.put_line('zbyt dużo SA_MAN!');
        
        commit;
        
        end;
           
        
        procedure salary_change (p_job_id IN varchar2, p_amount IN number, p_number_accepted OUT number, p_number_rejected OUT number)
        is
            CURSOR c_emp IS select * from employees where job_id = p_job_id for update;
            v_accepted number(5) := 0;
            v_rejected number(5) := 0;
        
        begin
            for r_emp in c_emp loop
            
            if p_amount / r_emp.salary < 1.25 then
            
                v_accepted := v_accepted + 1;   
                update employees
                set salary = salary + p_amount
                where current of c_emp;
            
            else
            
                v_rejected := v_rejected + 1;
            
            end if;
            
            end loop;
            
            p_number_accepted := v_accepted;
            p_number_rejected := v_rejected;
        
        end;
           
        
        procedure best_payroll (N number)
        is
            CURSOR c_job_id IS select distinct job_id from employees;
            CURSOR c_emp(p_job_id varchar2) IS select *
                                                  from employees
                                                  where job_id = p_job_id
                                                  order by salary desc;
            v_job_id employees.job_id%type;
        begin
        
            for r_job_id in c_job_id loop
                v_job_id := r_job_id.job_id;
                
                for r_emp in c_emp(v_job_id) loop
                    if c_emp%rowcount <= n then
                    dbms_output.put_line(r_emp.last_name || ' ' || r_emp.first_name ||  ' ' || r_emp.salary);
                    end if;
                
                end loop;
            
            end loop;
        
        end;
        
           
        function salary_ranking (p_employee_id number) return number
        is
            CURSOR c_emp IS select * from employees order by salary desc;
            ranking number(10) := 0;
        
        begin
        
            for r_emp in c_emp loop
        
                ranking := ranking + 1;
        
                if r_emp.employee_id = p_employee_id then
                return ranking;
                end if;
            
            end loop;
        
        end;


        function salary_ranking (p_last_name varchar2) return number
        is
            CURSOR c_emp IS select * from employees order by salary desc;
            ranking number(10) := 0;
        
        begin
        
            for r_emp in c_emp loop
        
                ranking := ranking + 1;
        
                if r_emp.last_name = p_last_name then
                    return ranking;
                end if;
            
            end loop;
        
        end;
      
        
        function salary_ranking_dep  (p_employee_id number) return number
        is
            CURSOR c_emp(pc_department_id number) IS select * from employees where department_id = pc_department_id order by salary desc;
            ranking number(10) := 0;
            dep_num employees.department_id%type;
        
        begin
        
            select department_id into dep_num 
            from employees
            where employee_id = p_employee_id;
        
            for r_emp in c_emp(dep_num) loop
        
                ranking := ranking + 1;
        
                if r_emp.employee_id = p_employee_id then
                return ranking;
                end if;
            
            end loop;
        
        end;

end;



begin 
    dbms_output.put_line('pozycja w firmie ' ||zajecia8.salary_ranking(104));
    dbms_output.put_line('pozycja w dep. ' || zajecia8.salary_ranking_dep(104));
    best_payroll(2);
    dbms_output.put_line('pozycja w firmie ' ||zajecia8.salary_ranking('King'));
end;

