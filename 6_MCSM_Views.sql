USE MCSM
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- View1 (vw_onlinePaymentPackage) -- View to see Package information that are NOT paid by CASH

CREATE VIEW vw_onlinePaymentPackage as (
    SELECT P.Package_ID, P.Package_Weight,PT.Payment_Type_Name,Pay.Total_Amount, P.Last_Updated_Location, P.Delivery_Status,P.Shipment_ID,P.Warehouse_ID  
    FROM Package P INNER JOIN Payments Pay 
    ON P.Package_ID=Pay.Package_ID
    INNER JOIN Payment_Type PT 
    ON Pay.Payment_Type_ID=PT.Payment_Type_ID 
    WHERE PT.Payment_Type_Name NOT IN ('CASH')
);
GO

--Select * from  vw_onlinePaymentPackage
--GO

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- View2 (vw_highPriorityCustomers) -- View to see Information of customers that have 'ONE DAY RUSH' priority packages

CREATE VIEW vw_highPriorityCustomers AS
(
    Select C.Customer_ID, C.Customer_Name, C.Contact_Number, C.Email_ID, C.[State],C.Postal_Code, C.Street_Address, PR.Priority_Type,PR.Priority_Description
    from CUSTOMER C INNER JOIN Package Pack 
    ON  C.CUSTOMER_ID= Pack.CUSTOMER_ID
    INNER JOIN PRIORITY PR
    ON Pack.Priority_ID = PR.priority_id 
    Where PR.Priority_Description = 'One Day Rush'
);
GO

--Select * from vw_highPriorityCustomers
--GO

---------------------------------------------------------------------------------------------------------------------------------------------------------
-- View3 (vw_pickupOrders) -- View to see Package Information having delivery mode as Pick up


CREATE VIEW vw_pickupOrders AS 
(
    SELECT P.Package_ID, P.Package_Weight, P.Last_Updated_Location, P.Delivery_Status,P.Shipment_ID,P.Warehouse_ID, D.Delivery_Mode_Type,D.Delivery_Mode_Description
    From Package P Inner Join Delivery_mode D 
    ON P.Delivery_Mode_ID=D.Delivery_Mode_ID
    Where D.Delivery_Mode_Description='Pickup'
);
GO

--Select * from vw_pickupOrders
--GO

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- View4 (vw_employeeDecrytedSSN) --View to retrieve decryted SSN of Emplpoyees

--OPEN SYMMETRIC KEY EmpSSN_SM  
--DECRYPTION BY CERTIFICATE EmpSSN;

CREATE VIEW vw_employeeDecrytedSSN AS
(
    Select Employee_ID, Employee_name, convert(varchar, DECRYPTBYKEY(SSN)) as SSN from Employee
)

--SELECT * FROM vw_employeeDecrytedSSN;
--GO

-----------------------------------------------------------------------------------------------------------------------------------------------------------