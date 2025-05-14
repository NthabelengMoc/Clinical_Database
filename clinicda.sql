CREATE DATABASE clinicdb;

-- 1. Patient information
CREATE TABLE Patients (
    patient_id INT PRIMARY KEY,
    id_number VARCHAR(13) UNIQUE, -- South African ID number
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender CHAR(1) CHECK (gender IN ('M', 'F', 'O')), -- M=Male, F=Female, O=Other
    phone_number VARCHAR(15),
    email VARCHAR(100),
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    suburb VARCHAR(50),
    city VARCHAR(50),
    province VARCHAR(50),
    postal_code VARCHAR(10),
    medical_aid_number VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Medical Aid Schemes
CREATE TABLE MedicalAidSchemes (
    scheme_id INT PRIMARY KEY,
    scheme_name VARCHAR(100) NOT NULL,
    contact_number VARCHAR(15),
    email VARCHAR(100),
    website VARCHAR(100)
);

-- 3. Patient Medical Aid Details
CREATE TABLE PatientMedicalAid (
    patient_medical_aid_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    scheme_id INT NOT NULL,
    membership_number VARCHAR(50) NOT NULL,
    principal_member_name VARCHAR(100),
    relationship_to_principal VARCHAR(50),
    plan_type VARCHAR(50),
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (scheme_id) REFERENCES MedicalAidSchemes(scheme_id)
);

-- 4. Healthcare Facilities
CREATE TABLE Facilities (
    facility_id INT PRIMARY KEY,
    facility_name VARCHAR(100) NOT NULL,
    facility_type VARCHAR(50) NOT NULL, -- Hospital, Clinic, Private Practice, etc.
    practice_number VARCHAR(50), -- Practice number for billing
    phone_number VARCHAR(15),
    email VARCHAR(100),
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    suburb VARCHAR(50),
    city VARCHAR(50),
    province VARCHAR(50),
    postal_code VARCHAR(10),
    operating_hours TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Healthcare Providers
CREATE TABLE HealthcareProviders (
    provider_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    hpcsa_number VARCHAR(20) UNIQUE, -- Health Professions Council of South Africa number
    specialization VARCHAR(100),
    phone_number VARCHAR(15),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Provider-Facility Relationship (Many-to-Many)
CREATE TABLE ProviderFacilities (
    provider_facility_id INT PRIMARY KEY,
    provider_id INT NOT NULL,
    facility_id INT NOT NULL,
    primary_facility BOOLEAN DEFAULT FALSE,
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (provider_id) REFERENCES HealthcareProviders(provider_id),
    FOREIGN KEY (facility_id) REFERENCES Facilities(facility_id),
    UNIQUE (provider_id, facility_id) -- Prevent duplicate assignments
);

-- 7. Visit Types
CREATE TABLE VisitTypes (
    visit_type_id INT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    description TEXT,
    standard_duration_minutes INT,
    tariff_code VARCHAR(20) -- Standard tariff code for this visit type
);

-- 8. Clinical Visits
CREATE TABLE ClinicalVisits (
    visit_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    facility_id INT NOT NULL,
    provider_id INT NOT NULL,
    visit_type_id INT NOT NULL,
    visit_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME,
    status VARCHAR(20) NOT NULL CHECK (status IN ('SCHEDULED', 'CHECKED_IN', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW')),
    visit_reason TEXT,
    notes TEXT,
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (facility_id) REFERENCES Facilities(facility_id),
    FOREIGN KEY (provider_id) REFERENCES HealthcareProviders(provider_id),
    FOREIGN KEY (visit_type_id) REFERENCES VisitTypes(visit_type_id)
);

-- 9. Vital Signs
CREATE TABLE VitalSigns (
    vital_id INT PRIMARY KEY,
    visit_id INT NOT NULL,
    recorded_by_provider_id INT NOT NULL,
    recorded_at TIMESTAMP NOT NULL,
    temperature DECIMAL(4,1), -- in Celsius
    blood_pressure_systolic INT,
    blood_pressure_diastolic INT,
    heart_rate INT, -- bpm
    respiratory_rate INT, -- breaths per minute
    oxygen_saturation INT, -- percentage
    weight DECIMAL(5,2), -- in kg
    height DECIMAL(5,2), -- in cm
    bmi DECIMAL(4,1),
    notes TEXT,
    FOREIGN KEY (visit_id) REFERENCES ClinicalVisits(visit_id),
    FOREIGN KEY (recorded_by_provider_id) REFERENCES HealthcareProviders(provider_id)
);

-- 10. Diagnoses
CREATE TABLE Diagnoses (
    diagnosis_id INT PRIMARY KEY,
    visit_id INT NOT NULL,
    icd10_code VARCHAR(10) NOT NULL, -- ICD-10 diagnostic code
    diagnosis_description TEXT NOT NULL,
    diagnosis_date DATE NOT NULL,
    diagnosed_by_provider_id INT NOT NULL,
    primary_diagnosis BOOLEAN DEFAULT FALSE,
    notes TEXT,
    FOREIGN KEY (visit_id) REFERENCES ClinicalVisits(visit_id),
    FOREIGN KEY (diagnosed_by_provider_id) REFERENCES HealthcareProviders(provider_id)
);

-- 11. Medications/Prescriptions
CREATE TABLE Medications (
    medication_id INT PRIMARY KEY,
    nappi_code VARCHAR(20) NOT NULL, -- South African National Pharmaceutical Product Index code
    medication_name VARCHAR(100) NOT NULL,
    active_ingredient VARCHAR(100),
    strength VARCHAR(50),
    form VARCHAR(50), -- tablet, capsule, syrup, etc.
    schedule INT CHECK (schedule BETWEEN 0 AND 8) -- South African medication scheduling
);

-- 12. Prescriptions
CREATE TABLE Prescriptions (
    prescription_id INT PRIMARY KEY,
    visit_id INT NOT NULL,
    prescribed_by_provider_id INT NOT NULL,
    prescription_date DATE NOT NULL,
    valid_until_date DATE,
    dispensed BOOLEAN DEFAULT FALSE,
    dispensed_date DATE,
    notes TEXT,
    FOREIGN KEY (visit_id) REFERENCES ClinicalVisits(visit_id),
    FOREIGN KEY (prescribed_by_provider_id) REFERENCES HealthcareProviders(provider_id)
);

-- 13. Prescription Items (details of medications in a prescription)
CREATE TABLE PrescriptionItems (
    prescription_item_id INT PRIMARY KEY,
    prescription_id INT NOT NULL,
    medication_id INT NOT NULL,
    dosage VARCHAR(50) NOT NULL,
    frequency VARCHAR(50) NOT NULL,
    duration VARCHAR(50),
    quantity INT NOT NULL,
    repeats INT DEFAULT 0,
    instructions TEXT,
    FOREIGN KEY (prescription_id) REFERENCES Prescriptions(prescription_id),
    FOREIGN KEY (medication_id) REFERENCES Medications(medication_id)
);

-- 14. Laboratory Tests
CREATE TABLE LabTests (
    test_id INT PRIMARY KEY,
    test_code VARCHAR(20) NOT NULL,
    test_name VARCHAR(100) NOT NULL,
    description TEXT,
    sample_type VARCHAR(50), -- blood, urine, etc.
    turnaround_time_hours INT
);

-- 15. Lab Orders
CREATE TABLE LabOrders (
    lab_order_id INT PRIMARY KEY,
    visit_id INT NOT NULL,
    ordered_by_provider_id INT NOT NULL,
    order_date TIMESTAMP NOT NULL,
    status VARCHAR(20) CHECK (status IN ('ORDERED', 'COLLECTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    priority VARCHAR(20) DEFAULT 'ROUTINE' CHECK (priority IN ('ROUTINE', 'URGENT', 'STAT')),
    notes TEXT,
    FOREIGN KEY (visit_id) REFERENCES ClinicalVisits(visit_id),
    FOREIGN KEY (ordered_by_provider_id) REFERENCES HealthcareProviders(provider_id)
);

-- 16. Lab Order Items
CREATE TABLE LabOrderItems (
    lab_order_item_id INT PRIMARY KEY,
    lab_order_id INT NOT NULL,
    test_id INT NOT NULL,
    result TEXT,
    reference_range VARCHAR(100),
    result_date TIMESTAMP,
    abnormal BOOLEAN DEFAULT FALSE,
    comments TEXT,
    FOREIGN KEY (lab_order_id) REFERENCES LabOrders(lab_order_id),
    FOREIGN KEY (test_id) REFERENCES LabTests(test_id)
);

-- 17. Invoices
CREATE TABLE Invoices (
    invoice_id INT PRIMARY KEY,
    visit_id INT NOT NULL,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    invoice_date DATE NOT NULL,
    patient_id INT NOT NULL,
    medical_aid_submitted BOOLEAN DEFAULT FALSE,
    patient_portion DECIMAL(10,2),
    total_amount DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR(20) CHECK (status IN ('PENDING', 'PARTIAL', 'PAID', 'OVERDUE', 'CANCELLED')),
    payment_due_date DATE,
    notes TEXT,
    FOREIGN KEY (visit_id) REFERENCES ClinicalVisits(visit_id),
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

-- 18. Invoice Items
CREATE TABLE InvoiceItems (
    invoice_item_id INT PRIMARY KEY,
    invoice_id INT NOT NULL,
    item_description VARCHAR(200) NOT NULL,
    tariff_code VARCHAR(20),
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (invoice_id) REFERENCES Invoices(invoice_id)
);

-- Created additional indexes for performance optimization
CREATE INDEX idx_patients_lastname ON Patients(last_name);
CREATE INDEX idx_clinical_visits_date ON ClinicalVisits(visit_date);
CREATE INDEX idx_clinical_visits_patient ON ClinicalVisits(patient_id);
CREATE INDEX idx_diagnoses_icd10 ON Diagnoses(icd10_code);
CREATE INDEX idx_prescription_visit ON Prescriptions(visit_id);
CREATE INDEX idx_lab_orders_visit ON LabOrders(visit_id);
CREATE INDEX idx_invoices_patient ON Invoices(patient_id);


-- sample data

-- 1. Patient Information
INSERT INTO Patients (patient_id, id_number, first_name, last_name, date_of_birth, gender, phone_number, email, address_line1, address_line2, suburb, city, province, postal_code, medical_aid_number)
VALUES 
(1, '7801011234083', 'Thabo', 'Mbeki', '1978-01-01', 'M', '+27821234567', 'thabo.mbeki@example.com', '123 Mandela Street', NULL, 'Sandton', 'Johannesburg', 'Gauteng', '2196', 'DIS789456'),
(2, '8602023456084', 'Lerato', 'Motaung', '1986-02-02', 'F', '+27833456789', 'lerato.m@example.com', '45 Main Road', 'Apartment 302', 'Rondebosch', 'Cape Town', 'Western Cape', '7700', 'BON123789'),
(3, '9205035678085', 'Sipho', 'Nkosi', '1992-05-03', 'M', '+27845678901', 'sipho.n@example.com', '78 Church Street', NULL, 'Arcadia', 'Pretoria', 'Gauteng', '0083', 'MED456123'),
(4, '6507047890086', 'Nomsa', 'Dlamini', '1965-07-04', 'F', '+27857890123', 'nomsa.d@example.com', '15 Beach Road', NULL, 'Umhlanga', 'Durban', 'KwaZulu-Natal', '4320', 'FED789012'),
(5, '8909059012087', 'Vusi', 'Zuma', '1989-09-05', 'M', '+27869012345', 'vusi.z@example.com', '56 Park Avenue', 'Unit 12', 'Kimberley Central', 'Kimberley', 'Northern Cape', '8301', 'DIS234567'),
(6, '7305062234088', 'Fatima', 'Ismail', '1973-05-06', 'F', '+27871234567', 'fatima.i@example.com', '23 Long Street', NULL, 'Hatfield', 'Pretoria', 'Gauteng', '0028', 'MOM345678'),
(7, '9107073456089', 'Andile', 'Ngcobo', '1991-07-07', 'M', '+27883456789', 'andile.n@example.com', '67 Voortrekker Road', NULL, 'Bellville', 'Cape Town', 'Western Cape', '7530', 'BON456789'),
(8, '8803085678080', 'Zanele', 'Ntuli', '1988-03-08', 'F', '+27895678901', 'zanele.n@example.com', '34 River Road', 'Block B', 'Berea', 'Durban', 'KwaZulu-Natal', '4001', 'GEM567890'),
(9, '6008097890081', 'Mandla', 'Khumalo', '1960-08-09', 'M', '+27817890123', 'mandla.k@example.com', '91 President Street', NULL, 'Germiston', 'Johannesburg', 'Gauteng', '1401', 'MED678901'),
(10, '9410109012082', 'Precious', 'Mokoena', '1994-10-10', 'F', '+27829012345', 'precious.m@example.com', '12 Adderley Street', NULL, 'Central', 'Port Elizabeth', 'Eastern Cape', '6001', 'DIS901234');

-- 2. Medical Aid Schemes
INSERT INTO MedicalAidSchemes (scheme_id, scheme_name, contact_number, email, website)
VALUES 
(1, 'Discovery Health', '+27860992654', 'info@discovery.co.za', 'www.discovery.co.za'),
(2, 'Bonitas Medical Fund', '+27860002108', 'info@bonitas.co.za', 'www.bonitas.co.za'),
(3, 'Momentum Health', '+27860102493', 'healthadvisor@momentum.co.za', 'www.momentumhealth.co.za'),
(4, 'Medihelp', '+27860100678', 'enquiries@medihelp.co.za', 'www.medihelp.co.za'),
(5, 'Fedhealth', '+27860002153', 'member@fedhealth.co.za', 'www.fedhealth.co.za'),
(6, 'GEMS (Government Employees Medical Scheme)', '+27860004367', 'enquiries@gems.gov.za', 'www.gems.gov.za'),
(7, 'Bestmed', '+27860002378', 'service@bestmed.co.za', 'www.bestmed.co.za'),
(8, 'Medshield', '+27860002020', 'member@medshield.co.za', 'www.medshield.co.za');

-- 3. Patient Medical Aid Details
INSERT INTO PatientMedicalAid (patient_medical_aid_id, patient_id, scheme_id, membership_number, principal_member_name, relationship_to_principal, plan_type, start_date, end_date)
VALUES 
(1, 1, 1, 'DIS123456789', 'Thabo Mbeki', 'SELF', 'Executive Plan', '2020-01-01', NULL),
(2, 2, 2, 'BON987654321', 'Lerato Motaung', 'SELF', 'BonComprehensive', '2019-03-15', NULL),
(3, 3, 4, 'MED456789123', 'Sipho Nkosi', 'SELF', 'MediValue', '2021-05-01', NULL),
(4, 4, 5, 'FED789123456', 'Jabulani Dlamini', 'SPOUSE', 'Maxima Executive', '2018-07-10', NULL),
(5, 5, 1, 'DIS234567890', 'Vusi Zuma', 'SELF', 'Classic Saver', '2022-01-01', NULL),
(6, 6, 3, 'MOM345678901', 'Ismail Mohamed', 'SPOUSE', 'Ingwe Option', '2017-11-20', NULL),
(7, 7, 2, 'BON456789012', 'Andile Ngcobo', 'SELF', 'BonSave', '2021-02-15', NULL),
(8, 8, 6, 'GEM567890123', 'Zanele Ntuli', 'SELF', 'Emerald Value', '2020-04-01', NULL),
(9, 9, 4, 'MED678901234', 'Mandla Khumalo', 'SELF', 'MediPhila', '2019-08-01', NULL),
(10, 10, 1, 'DIS901234567', 'Precious Mokoena', 'SELF', 'KeyCare Plus', '2022-03-01', NULL);

-- 4. Healthcare Facilities
INSERT INTO Facilities (facility_id, facility_name, facility_type, practice_number, phone_number, email, address_line1, address_line2, suburb, city, province, postal_code, operating_hours)
VALUES 
(1, 'Netcare Sandton Hospital', 'Hospital', 'PRAC123456', '+27112505000', 'info.sandton@netcare.co.za', '114 West Street', NULL, 'Sandton', 'Johannesburg', 'Gauteng', '2196', 'Open 24 hours'),
(2, 'Mediclinic Cape Town', 'Hospital', 'PRAC234567', '+27214647500', 'info.capetown@mediclinic.co.za', '21 Hof Street', NULL, 'Oranjezicht', 'Cape Town', 'Western Cape', '8001', 'Open 24 hours'),
(3, 'Life Kingsbury Hospital', 'Hospital', 'PRAC345678', '+27217621250', 'info.kingsbury@lifehealthcare.co.za', 'Wilderness Road', NULL, 'Claremont', 'Cape Town', 'Western Cape', '7708', 'Open 24 hours'),
(4, 'Ahmed Kathrada Private Hospital', 'Hospital', 'PRAC456789', '+27112141000', 'info.kathrada@lenmed.co.za', 'K43 Highway', NULL, 'Lenasia Ext 8', 'Johannesburg', 'Gauteng', '1827', 'Open 24 hours'),
(5, 'Pretoria East Family Practice', 'Private Practice', 'PRAC567890', '+27124607500', 'reception@preasterndocs.co.za', '123 Garsfontein Road', 'Ashlea Gardens', 'Pretoria East', 'Pretoria', 'Gauteng', '0181', 'Mon-Fri: 08:00-17:00, Sat: 08:00-13:00'),
(6, 'Umhlanga Medical Centre', 'Clinic', 'PRAC678901', '+27315663320', 'admin@umhlangamc.co.za', '323 Umhlanga Rocks Drive', NULL, 'Umhlanga', 'Durban', 'KwaZulu-Natal', '4320', 'Mon-Sun: 07:00-22:00'),
(7, 'Kimberley Medical Centre', 'Private Practice', 'PRAC789012', '+27538324760', 'reception@kimbmedcentre.co.za', '45 Du Toitspan Road', NULL, 'Kimberley Central', 'Kimberley', 'Northern Cape', '8301', 'Mon-Fri: 08:00-17:00'),
(8, 'Hatfield City Clinic', 'Clinic', 'PRAC890123', '+27124320987', 'info@hatfieldclinic.co.za', '567 Pretorius Street', NULL, 'Hatfield', 'Pretoria', 'Gauteng', '0028', 'Mon-Sat: 08:00-20:00, Sun: 09:00-13:00'),
(9, 'Durban Beachfront Medical', 'Private Practice', 'PRAC901234', '+27313047890', 'admin@dbfmedical.co.za', '56 OR Tambo Parade', NULL, 'North Beach', 'Durban', 'KwaZulu-Natal', '4001', 'Mon-Fri: 07:30-18:00, Sat: 08:00-13:00'),
(10, 'Khayelitsha Community Clinic', 'Clinic', 'PRAC012345', '+27213614200', 'khayelitsha.clinic@westerncape.gov.za', 'Site B', NULL, 'Khayelitsha', 'Cape Town', 'Western Cape', '7784', 'Mon-Fri: 07:30-16:30');

-- 5. Healthcare Providers
INSERT INTO HealthcareProviders (provider_id, first_name, last_name, hpcsa_number, specialization, phone_number, email)
VALUES 
(1, 'Nkosazana', 'Dlamini', 'MP0123456', 'General Practitioner', '+27824561234', 'nkosazana.d@medicalpractice.co.za'),
(2, 'John', 'van der Merwe', 'MP0234567', 'Cardiologist', '+27835672345', 'john.vdm@heartspecialists.co.za'),
(3, 'Priya', 'Naidoo', 'MP0345678', 'Pediatrician', '+27846783456', 'priya.n@kidshealth.co.za'),
(4, 'Thulani', 'Sithole', 'MP0456789', 'Dermatologist', '+27857894567', 'thulani.s@skincare.co.za'),
(5, 'Sarah', 'Goldstein', 'MP0567890', 'Obstetrician/Gynecologist', '+27868905678', 'sarah.g@womenshealth.co.za'),
(6, 'Mohammed', 'Patel', 'MP0678901', 'Orthopedic Surgeon', '+27879016789', 'mohammed.p@orthocare.co.za'),
(7, 'Nosipho', 'Mthembu', 'MP0789012', 'Psychiatrist', '+27880127890', 'nosipho.m@mentalhealth.co.za'),
(8, 'James', 'Wilson', 'MP0890123', 'Neurologist', '+27891238901', 'james.w@brainhealth.co.za'),
(9, 'Busisiwe', 'Mahlangu', 'MP0901234', 'Family Medicine', '+27802349012', 'busisiwe.m@familycare.co.za'),
(10, 'Ahmed', 'Ismail', 'MP0012345', 'Gastroenterologist', '+27813450123', 'ahmed.i@digestivehealth.co.za');

-- 6. Provider-Facility Relationship
INSERT INTO ProviderFacilities (provider_facility_id, provider_id, facility_id, primary_facility, start_date, end_date)
VALUES 
(1, 1, 5, TRUE, '2018-01-15', NULL),
(2, 2, 1, TRUE, '2017-06-01', NULL),
(3, 2, 4, FALSE, '2019-03-01', NULL),
(4, 3, 2, TRUE, '2020-02-01', NULL),
(5, 4, 9, TRUE, '2019-08-15', NULL),
(6, 5, 3, TRUE, '2015-11-01', NULL),
(7, 5, 2, FALSE, '2018-05-01', NULL),
(8, 6, 6, TRUE, '2021-01-10', NULL),
(9, 7, 5, TRUE, '2019-07-01', NULL),
(10, 8, 1, TRUE, '2017-09-15', NULL),
(11, 9, 10, TRUE, '2018-03-01', NULL),
(12, 10, 4, TRUE, '2020-08-01', NULL);

-- 7. Visit Types
INSERT INTO VisitTypes (visit_type_id, type_name, description, standard_duration_minutes, tariff_code)
VALUES 
(1, 'Initial Consultation', 'First visit with the healthcare provider', 30, '0190'),
(2, 'Follow-up Consultation', 'Subsequent visit for ongoing care', 15, '0191'),
(3, 'Annual Check-up', 'Yearly comprehensive health assessment', 45, '0192'),
(4, 'Emergency Visit', 'Unscheduled visit for urgent care', 30, '0193'),
(5, 'Specialist Consultation', 'Consultation with a specialist', 45, '0194'),
(6, 'Procedure', 'Visit for a specific medical procedure', 60, '0195'),
(7, 'Immunization', 'Visit for vaccine administration', 15, '0196'),
(8, 'Chronic Disease Management', 'Visit for managing ongoing chronic conditions', 30, '0197'),
(9, 'Prenatal Check-up', 'Regular monitoring during pregnancy', 30, '0198'),
(10, 'Mental Health Session', 'Consultation for mental health concerns', 60, '0199');

-- 8. Clinical Visits
INSERT INTO ClinicalVisits (visit_id, patient_id, facility_id, provider_id, visit_type_id, visit_date, start_time, end_time, status, visit_reason, notes, follow_up_required, follow_up_date)
VALUES 
(1, 1, 5, 1, 1, '2023-03-10', '09:00:00', '09:30:00', 'COMPLETED', 'Persistent cough and fever', 'Patient presented with symptoms of upper respiratory infection. Prescribed antibiotics.', TRUE, '2023-03-20'),
(2, 2, 2, 3, 9, '2023-03-10', '10:00:00', '10:30:00', 'COMPLETED', 'Routine prenatal check-up', '28 weeks pregnant, all vital signs normal. Fetal heartbeat strong.', TRUE, '2023-03-24'),
(3, 3, 5, 7, 10, '2023-03-11', '14:00:00', '15:00:00', 'COMPLETED', 'Anxiety management', 'Patient reports improved sleep but still experiencing work-related anxiety.', TRUE, '2023-04-01'),
(4, 4, 6, 6, 8, '2023-03-12', '11:00:00', '11:30:00', 'COMPLETED', 'Diabetes follow-up', 'Blood glucose levels have improved. Continuing current medication regimen.', TRUE, '2023-04-12'),
(5, 5, 1, 2, 5, '2023-03-13', '13:00:00', '13:45:00', 'COMPLETED', 'Chest pain investigation', 'ECG performed. Results show normal sinus rhythm. Stress test scheduled.', TRUE, '2023-03-20'),
(6, 6, 8, 9, 3, '2023-03-14', '09:30:00', '10:15:00', 'COMPLETED', 'Annual physical examination', 'All parameters within normal range. Recommended increased physical activity.', FALSE, NULL),
(7, 7, 2, 5, 9, '2023-03-15', '15:00:00', '15:30:00', 'COMPLETED', 'First prenatal visit', 'Confirmed pregnancy at 8 weeks. Prescribed prenatal vitamins.', TRUE, '2023-03-29'),
(8, 8, 1, 8, 5, '2023-03-16', '10:00:00', '10:45:00', 'COMPLETED', 'Recurring headaches', 'Neurological examination normal. Prescribed migraine medication.', TRUE, '2023-04-06'),
(9, 9, 4, 10, 5, '2023-03-17', '11:30:00', '12:15:00', 'COMPLETED', 'Abdominal pain', 'Suspected IBS. Recommended dietary changes and prescribed antispasmodics.', TRUE, '2023-04-07'),
(10, 10, 10, 9, 1, '2023-03-18', '08:30:00', '09:00:00', 'COMPLETED', 'High blood pressure', 'Initial reading 150/95. Prescribed antihypertensive medication.', TRUE, '2023-04-01'),
(11, 1, 5, 1, 2, '2023-03-20', '14:00:00', '14:15:00', 'COMPLETED', 'Follow-up for respiratory infection', 'Symptoms resolved. Completed antibiotic course.', FALSE, NULL),
(12, 2, 2, 3, 9, '2023-03-24', '11:00:00', '11:30:00', 'COMPLETED', 'Prenatal check-up', '29 weeks pregnant, mild anemia detected. Iron supplements prescribed.', TRUE, '2023-04-07'),
(13, 5, 1, 2, 6, '2023-03-20', '09:00:00', '10:00:00', 'COMPLETED', 'Stress test', 'No abnormalities detected during exercise. Normal cardiac function.', FALSE, NULL),
(14, 10, 10, 9, 2, '2023-04-01', '09:00:00', '09:15:00', 'COMPLETED', 'Blood pressure check', 'BP improved to 135/85. Continuing current medication.', TRUE, '2023-05-01'),
(15, 3, 5, 7, 10, '2023-04-01', '15:30:00', '16:30:00', 'COMPLETED', 'Anxiety therapy session', 'Discussed coping strategies for work stress. Some improvement noted.', TRUE, '2023-04-22'),
(16, 7, 2, 5, 9, '2023-03-29', '14:00:00', '14:30:00', 'COMPLETED', 'Prenatal check-up', '10 weeks pregnant, normal progression. Scheduled ultrasound.', TRUE, '2023-04-12'),
(17, 8, 1, 8, 2, '2023-04-06', '11:00:00', '11:15:00', 'COMPLETED', 'Headache follow-up', 'Reduced frequency of migraines with medication. Continuing current regimen.', TRUE, '2023-05-06'),
(18, 9, 4, 10, 2, '2023-04-07', '13:30:00', '13:45:00', 'COMPLETED', 'IBS follow-up', 'Symptoms improved with dietary changes. Continuing management plan.', TRUE, '2023-05-07'),
(19, 4, 6, 6, 8, '2023-04-12', '10:00:00', '10:30:00', 'COMPLETED', 'Diabetes management', 'HbA1c improved to 6.9%. Continued diet and exercise recommendations.', TRUE, '2023-06-12'),
(20, 7, 2, 5, 6, '2023-04-12', '15:00:00', '16:00:00', 'COMPLETED', 'First trimester ultrasound', 'Normal fetal development. Estimated due date confirmed as October 28, 2023.', TRUE, '2023-04-26');

-- 9. Vital Signs
INSERT INTO VitalSigns (vital_id, visit_id, recorded_by_provider_id, recorded_at, temperature, blood_pressure_systolic, blood_pressure_diastolic, heart_rate, respiratory_rate, oxygen_saturation, weight, height, bmi, notes)
VALUES 
(1, 1, 1, '2023-03-10 09:05:00', 38.2, 125, 80, 88, 18, 97, 78.5, 175.0, 25.6, 'Elevated temperature consistent with infection'),
(2, 2, 3, '2023-03-10 10:05:00', 36.8, 110, 70, 82, 16, 99, 65.2, 163.0, 24.5, 'Normal vital signs for pregnancy'),
(3, 3, 7, '2023-03-11 14:05:00', 36.7, 130, 85, 90, 17, 98, 82.3, 178.0, 26.0, 'Slightly elevated BP due to anxiety'),
(4, 4, 6, '2023-03-12 11:05:00', 36.5, 135, 82, 76, 15, 97, 68.9, 160.0, 26.9, 'BP still above target range'),
(5, 5, 2, '2023-03-13 13:05:00', 36.6, 128, 78, 85, 16, 98, 85.6, 182.0, 25.8, 'BP within normal limits'),
(6, 6, 9, '2023-03-14 09:35:00', 36.8, 118, 75, 72, 14, 99, 70.1, 165.0, 25.7, 'All vitals within normal range'),
(7, 7, 5, '2023-03-15 15:05:00', 36.9, 115, 72, 80, 16, 99, 62.8, 168.0, 22.3, 'Normal vital signs'),
(8, 8, 8, '2023-03-16 10:05:00', 36.6, 120, 80, 78, 15, 98, 75.3, 170.0, 26.1, 'Normal vital signs'),
(9, 9, 10, '2023-03-17 11:35:00', 36.7, 122, 78, 75, 15, 98, 80.5, 175.0, 26.3, 'Normal vital signs'),
(10, 10, 9, '2023-03-18 08:35:00', 36.6, 150, 95, 82, 16, 97, 90.2, 180.0, 27.8, 'Hypertension noted'),
(11, 11, 1, '2023-03-20 14:05:00', 36.7, 122, 78, 76, 15, 99, 78.5, 175.0, 25.6, 'Returned to normal range'),
(12, 12, 3, '2023-03-24 11:05:00', 36.8, 112, 72, 84, 16, 98, 66.0, 163.0, 24.8, 'Slight weight gain since last visit'),
(13, 13, 2, '2023-03-20 09:05:00', 36.5, 132, 82, 95, 17, 98, 85.6, 182.0, 25.8, 'Elevated heart rate during stress test - normal response'),
(14, 14, 9, '2023-04-01 09:05:00', 36.7, 135, 85, 80, 15, 98, 89.8, 180.0, 27.7, 'BP improved but still monitoring'),
(15, 15, 7, '2023-04-01 15:35:00', 36.6, 128, 82, 86, 16, 98, 82.3, 178.0, 26.0, 'BP slightly elevated during discussion of stressors');

-- 10. Diagnoses
INSERT INTO Diagnoses (diagnosis_id, visit_id, icd10_code, diagnosis_description, diagnosis_date, diagnosed_by_provider_id, primary_diagnosis, notes)
VALUES 
(1, 1, 'J06.9', 'Acute upper respiratory infection, unspecified', '2023-03-10', 1, TRUE, 'Likely viral infection'),
(2, 2, 'Z34.2', 'Normal second trimester pregnancy', '2023-03-10', 3, TRUE, 'Pregnancy progressing normally'),
(3, 3, 'F41.1', 'Generalized anxiety disorder', '2023-03-11', 7, TRUE, 'Work-related stressors identified'),
(4, 4, 'E11.9', 'Type 2 diabetes mellitus without complications', '2023-03-12', 6, TRUE, 'Well-controlled with medication'),
(5, 5, 'R07.9', 'Chest pain, unspecified', '2023-03-13', 2, TRUE, 'No evidence of cardiac pathology'),
(6, 6, 'Z00.00', 'Encounter for general adult medical examination without abnormal findings', '2023-03-14', 9, TRUE, 'Annual check-up with normal findings'),
(7, 7, 'Z34.0', 'Normal first trimester pregnancy', '2023-03-15', 5, TRUE, 'First pregnancy confirmed'),
(8, 8, 'G43.9', 'Migraine, unspecified', '2023-03-16', 8, TRUE, 'Recurring headaches consistent with migraine pattern'),
(9, 9, 'K58.9', 'Irritable bowel syndrome without diarrhea', '2023-03-17', 10, TRUE, 'Symptoms consistent with IBS'),
(10, 10, 'I10', 'Essential (primary) hypertension', '2023-03-18', 9, TRUE, 'Newly diagnosed hypertension'),
(11, 12, 'D50.9', 'Iron deficiency anemia, unspecified', '2023-03-24', 3, FALSE, 'Mild anemia during pregnancy'),
(12, 15, 'F41.1', 'Generalized anxiety disorder', '2023-04-01', 7, TRUE, 'Ongoing management of previously diagnosed anxiety'),
(13, 18, 'K58.9', 'Irritable bowel syndrome without diarrhea', '2023-04-07', 10, TRUE, 'Continued management of IBS');

-- 11. Medications
INSERT INTO Medications (medication_id, nappi_code, medication_name, active_ingredient, strength, form, schedule)
VALUES 
(1, '719822001', 'Augmentin', 'Amoxicillin/Clavulanic Acid', '875mg/125mg', 'Tablet', 4),
(2, '710132001', 'Panado', 'Paracetamol', '500mg', 'Tablet', 2),
(3, '708735001', 'Glucophage', 'Metformin', '500mg', 'Tablet', 3),
(4, '714019001', 'Tenormin', 'Atenolol', '50mg', 'Tablet', 3),
(5, '711108001', 'Nurofen', 'Ibuprofen', '400mg', 'Tablet', 2),
(6, '716603001', 'Zantac', 'Ranitidine', '150mg', 'Tablet', 2),
(7, '719923001', 'Buscopan', 'Hyoscine Butylbromide', '10mg', 'Tablet', 2),
(8, '717845001', 'Nexiam', 'Esomeprazole', '20mg', 'Tablet', 3),
(9, '712534001', 'Prozac', 'Fluoxetine', '20mg', 'Capsule', 5),
(10, '716722001', 'Migril', 'Ergotamine/Caffeine/Cyclizine', '1mg/100mg/50mg', 'Tablet', 3),
(11, '715933001', 'Adalat XL', 'Nifedipine', '30mg', 'Tablet', 3),
(12, '718244001', 'Ferro-Gradumet', 'Ferrous Sulfate', '325mg', 'Tablet', 1),
(13, '713567001', 'Preggos', 'Multiple Vitamins and Minerals', 'Various', 'Tablet', 0),
(14, '720145001', 'Trepiline', 'Amitriptyline', '25mg', 'Tablet', 5),
(15, '717656001', 'Disprin', 'Aspirin', '325mg', 'Tablet', 1),
(16, '715478001', 'Metroclopramide', 'Metoclopramide', '10mg', 'Tablet', 3),
(17, '718901001', 'Adco-Bisocor', 'Bisoprolol', '5mg', 'Tablet', 3),
(18, '716789001', 'Aspen Citalopram', 'Citalopram', '20mg', 'Tablet', 5);