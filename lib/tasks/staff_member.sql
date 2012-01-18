-- this SQL script adds 3 new fields to staff_members.

ALTER TABLE `staff_members` ADD COLUMN `staff_designation` VARCHAR(30) NULL;
ALTER TABLE `staff_members` ADD COLUMN `staff_date_of_birth` DATE NULL;
ALTER TABLE `staff_members` ADD COLUMN `employee_id` VARCHAR(20) NULL;