ALTER TABLE `loan_applications`
 MODIFY COLUMN `amount` FLOAT  NOT NULL,
 MODIFY COLUMN `client_name` VARCHAR(50) NOT NULL,
 MODIFY COLUMN `client_dob` DATE  NOT NULL,
 MODIFY COLUMN `client_address` VARCHAR(50) NOT NULL,
 MODIFY COLUMN `client_pincode` INTEGER  NOT NULL,
 MODIFY COLUMN `client_reference1` VARCHAR(50) NOT NULL,
 MODIFY COLUMN `client_reference2` VARCHAR(50) NOT NULL,
 MODIFY COLUMN `client_guarantor_name` VARCHAR(50) NOT NULL,
 MODIFY COLUMN `client_state` INTEGER  NOT NULL,
 MODIFY COLUMN `received_on` DATE  NOT NULL,
 MODIFY COLUMN `created_on` DATE  NOT NULL;