-- Stored Procedures, Triggers and Audit Logging

-- 1. Create Department Table

CREATE TABLE Department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50)
);

INSERT INTO Department VALUES
(10, 'Computer Science'),
(20, 'Human Resources'),
(30, 'Finance'),
(40, 'Marketing'),
(50, 'Operations');


-- 2. Create Employee Table

CREATE TABLE Employee (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    salary DECIMAL(10,2),
    dept_id INT,
    FOREIGN KEY (dept_id)
        REFERENCES Department(dept_id)
);


-- 3. Create Employee Audit Table

CREATE TABLE Employee_Audit (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    previous_dept INT,
    updated_dept INT,
    previous_salary DECIMAL(10,2),
    updated_salary DECIMAL(10,2),
    modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 4. Trigger for Salary Validation on INSERT

DELIMITER $$

CREATE TRIGGER check_salary_insert
BEFORE INSERT ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary IS NULL OR NEW.salary <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid salary entered';
    END IF;
END$$


-- 5. Trigger for Salary Validation on UPDATE

CREATE TRIGGER check_salary_update
BEFORE UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary IS NULL OR NEW.salary <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Salary must be positive';
    END IF;
END$$


-- 6. Trigger for Employee Audit Logging

CREATE TRIGGER track_employee_changes
AFTER UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF NOT (OLD.dept_id <=> NEW.dept_id)
       OR NOT (OLD.salary <=> NEW.salary) THEN

        INSERT INTO Employee_Audit (
            employee_id,
            previous_dept,
            updated_dept,
            previous_salary,
            updated_salary
        )
        VALUES (
            OLD.emp_id,
            OLD.dept_id,
            NEW.dept_id,
            OLD.salary,
            NEW.salary
        );

    END IF;
END$$


-- 7. Stored Procedure for Employee Transfer

CREATE PROCEDURE transfer_employee(
    IN employee_no INT,
    IN target_department INT
)
BEGIN
    DECLARE emp_count INT DEFAULT 0;
    DECLARE dept_count INT DEFAULT 0;

    SELECT COUNT(*) INTO emp_count
    FROM Employee
    WHERE emp_id = employee_no;

    SELECT COUNT(*) INTO dept_count
    FROM Department
    WHERE dept_id = target_department;

    IF emp_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee ID not found';

    ELSEIF dept_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Department ID not found';

    ELSE
        UPDATE Employee
        SET dept_id = target_department
        WHERE emp_id = employee_no;
    END IF;
END$$

DELIMITER ;


-- 8. Insert Sample Employees

INSERT INTO Employee VALUES
(101, 'Rahul Verma', 45000, 10),
(102, 'Sneha Gupta', 52000, 20),
(103, 'Arjun Mehta', 60000, 30),
(104, 'Priya Sharma', 48000, 40),
(105, 'Rohan Das', 55000, 50);


-- 9. Display Employee Records

SELECT * FROM Employee;


-- 10. Transfer Employee to Another Department

CALL transfer_employee(101, 30);


-- 11. Check Employee After Transfer

SELECT emp_id, emp_name, dept_id
FROM Employee
WHERE emp_id = 101;


-- 12. Update Employee Salary

UPDATE Employee
SET salary = 58000
WHERE emp_id = 102;


-- 13. Display Audit Records

SELECT * FROM Employee_Audit;


-- 14. Test Invalid Salary

UPDATE Employee
SET salary = -5000
WHERE emp_id = 103;


-- 15. Test Invalid Employee

CALL transfer_employee(999, 20);


-- 16. Test Invalid Department

CALL transfer_employee(102, 999);


-- 17. Display Final Employee Details

SELECT * FROM Employee;
