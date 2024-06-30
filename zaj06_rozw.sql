-- pakiety PL/SQL

-- Pakiety PL/SQL są odpowiednikami bibliotek znanych z innych języków programowania

-- Pakiet pozwala na
-- - zadeklarowanie i zdefiniowanie procedur oraz funkcji
-- - przeciążanie procedur oraz funkcji
-- - zadeklarowanie typów, kursorów i wyjątków celem ich wielokrotnego wykorzystywania



-- Pakiet składa się z dwóch części
-- 1) specyfikacji, która zawiera deklaracje elementów (procedur, funkcji, typów (rekordy i tablice), kursorów i wyjątków) dostępnych na zewnątrz (publicznych)
-- 2) ciała, które zawiera   
--   - deklaracje typow, zmiennych, kursorów oraz wyjątków niedostępnych na zewn. pakietu (prywatnych)
--   - definicje procedur i funkcji zadeklarowanych w specyfikacji

-- Jeśli specyfikacja zawiera jedynie deklaracje kursorów oraz wyjątków, to ciało jest niepotrzebne.
-- Specyfikacja zatem może istnieć, być poprawna i być wykorzystywana bez ciała. Ciało bez specyfikacji natomiast zawsze jest niepoprawne.
  
-- Obydwie te składowe (specyfikację i ciało) tworzy się osobnymi poleceniami


-- specyfikacja:
CREATE [OR REPLACE] PACKAGE nazwa_pakietu
IS
	deklaracje typów, zmiennych, kursorów, wyjątków
	
	-- deklaracje funkcji (sam nagłówek)
	-- create or replace -> tego tutaj nie ma i być nie powinno
    function nazwa_funkcji(lista_parametrów) return typ_wyniku;
	...
	-- deklaracje procedur
	procedure nazwa_procedury(lista_parametrów);
	...
end;
/

-- przykład:
create or replace package pkg_emp_operations
is
	cursor c_emp is select * from employees;
	r_emp employees%rowtype;
	
    function get_max_sal(p_department_id number) return number;
	
	procedure drop_employee(p_employee_id number);
	
end;


describe employees;
-- ciało:
create or replace package body pkg_emp_operations
is
    function get_max_sal(p_department_id number) return number
	is
	    v_sal employees.salary%type;
	begin
	   select max(salary) 
	   into v_sal
	   from employees
	   where department_id = p_department_id;
	   
	   return v_sal;
	end;
	
	procedure drop_employee(p_employee_id number)
	is
	begin
	   delete from employees
	   where employee_id = p_employee_id;
	   
	   commit;
	end;
end;

begin
    pkg_emp_operations.drop_employee(999);
end;



-- przeciążanie (overloading)
-- Przeciążanie jest mechanizmem pozwalającym na definowanie kilku różnych procedur, bądź funkcji o tej samej nazwie, ale innej liście parametrów formalnych.
-- To, która wersja takiej procedury lub funkcji jest w danym momencie wołana, jest roztrzygane przez kompilator na etapie kompilacji kodu wołającego ów podprogram.

-- W PL/SQL możemy definiować przeciążane podprogramy jedynie dzięki pakietom.

-- przykład

create or replace package pkg_emp_operations_v2
is
	cursor c_emp is select * from employees;
	r_emp employees%rowtype;
	
    function get_max_sal(p_department_id number) return number;
	
	function get_max_sal(p_department_id number, p_job_id varchar2) return number; -- przeciążona wersja funkcji get_max_sal
	
	procedure drop_employee(p_employee_id number);
	
	procedure drop_employee(p_job_id varchar2);  -- przeciążona wersja procedury drop_employee

end;

-- ciało oczywiście musi zawierać definicje przeciążonych programów:
create or replace package body pkg_emp_operations_v2
is
    
    function get_max_sal(p_department_id number) return number
	is
	    v_sal employees.salary%type;
	begin
	   select max(salary) 
	   into v_sal
	   from employees
	   where department_id = p_department_id;
	   
	   return v_sal;
	end;
	
	function get_max_sal(p_department_id number, p_job_id varchar2) return number
	is
	    v_sal employees.salary%type;
	begin
	   select max(salary) 
	   into v_sal
	   from employees
	   where department_id = p_department_id
	     and job_id = p_job_id;
	   
	   return v_sal;
	end;
	
	procedure drop_employee(p_employee_id number)
	is
	begin
	   delete from employees
	   where employee_id = p_employee_id;
	   
	   commit;
	end;
	
    procedure drop_employee(p_job_id varchar2)
	is
	begin
	   delete from employees
	   where job_id = p_job_id;
	   
	   commit;
    end;
end;

-- odwoływanie się do składowych pakietów - stosujemy notację kropkową pakiet.składowa

-- np.

begin 
   pkg_emp_operations_v2.drop_employee(111);
end;

begin 
   pkg_emp_operations.drop_employee(111);
end;


begin 
   pkg_emp_operations.drop_employee('HR'); --tutaj błąd, bo pierwsza wersja pakietu (tj. pkg_emp_operations) nie obsługuje procedury drop_employee z parametrem tekstowym (nie ma przeciążenia) 
end;


begin 
   pkg_emp_operations_v2.drop_employee('HR'); --to działa, bo _v2 posiada przeciązenie procedury drop_employee, gdzie mamy 1 parametr tekstowy
end;

select last_name, department_id, job_id, salary
        , pkg_emp_operations_v2.get_max_sal(e.department_id) as max_sal_dep
        , pkg_emp_operations_v2.get_max_sal(e.department_id, e.job_id) as max_sal_dep_job
from employees e
order by department_id
;


-- zalety pakietów:
-- 1. pakiety pozwalają na grupowanie programów, zmiennych, wyjątków i typów o podobnym zastosowaniu
--    (np. w ramach danej aplikacji)
   
-- 2. pakiety pozwalają na przeciążanie procedur i funkcji

-- 3. pakiety pozwalają na deklaracje typów, zmiennych, kursorów i wyjątków, które później mogą
--    być wielokrotnie wykorzystywane
   
-- 4. pakiety pozwalają na lepsze zarządzanie pamięcią przeznaczoną na buforowanie kodu PL/SQL - 
--    ich stosowanie umożliwia zredukowanie fragmentacji tego obszaru pamięcią
  

-- zadanie
-- 1. stwórz pakiet PL/SQL dept_ops, który będzie grupował następujące procedury i funkcje:
--    a) procedure new_dept(p_department_id number, p_department_name varchar2) 
--       jej zadaniem będzie wstawianie nowego departamentu
--    b) procedure del_dept(p_department_id number)
--       jej zadaniem będzie usuwanie departamentu o podanym w parametrze identyfikatorze

create or replace package dept_ops
is
    procedure new_dept(p_department_id number, p_department_name varchar2);
    procedure del_dept(p_department_id number);
end;


create or replace package body dept_ops
is
    procedure new_dept(p_department_id number, p_department_name varchar2)
    is
    begin
        insert into departments(department_id, department_name)
        values (p_department_id, p_department_name);

        commit;
    end;

    procedure del_dept(p_department_id number)
    is
    begin
        delete from departments
        where department_id = p_department_id;    
    end;
end;

begin
    dept_ops.new_dept(953, 'HR');
end;

begin
    dept_ops.del_dept(953);
end;  



-- 2. w pakiecie dept_ops zdefiniuj
--    - przeciążoną wersję procedury new_dept
--      procedura ta winna przyjmować tylko jeden parametr formalny - p_department_name typu VARCHAR2,
--      natomiast wartość department_id dla nowego departamentu powinna wyznaczać automatycznie, odczytując max(department_id) i zwiększając owo maksimum o 1
     
--    - przeciążoną wersję procedury del_dept
--      procedura powinna przyjmować tylko jeden parametr formalny p_department_name typu VARCHAR2
--      procedura powinna usuwać departament o podanej w owym parametrze NAZWIE departamentu

create or replace package dept_ops_v2
is
    procedure new_dept(p_department_id number, p_department_name varchar2);
    procedure new_dept(p_department_name varchar2);

    procedure del_dept(p_department_id number);
    procedure del_dept(p_department_name varchar2);

end;


create or replace package body dept_ops_v2
is
    procedure new_dept(p_department_id number, p_department_name varchar2)
    is
    begin
        insert into departments(department_id, department_name)
        values (p_department_id, p_department_name);

        commit;
    end;

    procedure new_dept(p_department_name varchar2)
    is
        max_dep_id number(10);
    begin
        select max(department_id) into max_dep_id
        from departments;

        insert into departments(department_id, department_name)
            values (max_dep_id+1, p_department_name);
    end;

    procedure del_dept(p_department_id number)
    is
    begin
        delete from departments
        where department_id = p_department_id;    
    end;


    procedure del_dept(p_department_name varchar2)
    is
    begin
        delete from departments
        where department_name = p_department_name;
    end;

end;

begin
    dept_ops_v2.del_dept('HR');
end;


begin
    dept_ops_v2.new_dept('HR');
end;

select department_id, department_name
from departments
order by 1 desc
;