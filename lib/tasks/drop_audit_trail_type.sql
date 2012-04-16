alter table `audit_trail` add `user_role` INT not null;
alter table `audit_trail` drop `type`;