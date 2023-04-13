USE [MCSM]
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--SP1 (usp_InsertPackageDetails) - Inserts Package Details in Package Tabe and returns Package_ID

CREATE PROCEDURE usp_InsertPackageDetails
(
	@Package_Weight NUMERIC(3,1),
	@Last_Updated_Location varchar(20),
	@Package_Type_ID INT,
	@Delivery_Mode_ID INT,
	@Origin_Address_ID INT,
	@Destination_Address_ID INT,
	@Customer_ID INT,
	@Priority_ID INT,
	@Service_Location_Zipcode VARCHAR(5),
	@Office_ID INT,																													
    @Package_ID INT OUT 
) 
AS 
BEGIN

	DECLARE @ INT

	BEGIN TRY
		
		IF (@Package_Weight IS NULL)
		BEGIN
			RETURN -1
		END

		IF NOT EXISTS (SELECT Package_Type_ID FROM Package_Type WHERE Package_Type_ID = @Package_Type_ID)
		BEGIN
			RETURN -2
		END

		IF NOT EXISTS (SELECT Delivery_Mode_ID FROM Delivery_Mode WHERE Delivery_Mode_ID = @Delivery_Mode_ID)
		BEGIN
			RETURN -3
		END

		IF NOT EXISTS (SELECT Address_ID FROM Address WHERE Address_ID = @Origin_Address_ID)
		BEGIN
			RETURN -4
		END

		IF NOT EXISTS (SELECT Address_ID FROM Address WHERE Address_ID = @Destination_Address_ID)
		BEGIN
			RETURN -5
		END

		IF NOT EXISTS (SELECT Customer_ID FROM Customer WHERE Customer_ID = @Customer_ID)
		BEGIN
			RETURN -6
		END

		IF NOT EXISTS (SELECT Priority_ID FROM [Priority] WHERE Priority_ID = @Priority_ID)
		BEGIN
			RETURN -7
		END

		IF NOT EXISTS (SELECT Zipcode FROM Service_Location WHERE Zipcode = @Service_Location_Zipcode)
		BEGIN
			RETURN -8
		END

		IF NOT EXISTS (SELECT Office_ID FROM Offices WHERE Office_ID = @Office_ID)
		BEGIN
			RETURN -9
		END

		BEGIN
			BEGIN TRAN
				INSERT INTO Package(Package_Weight, Last_Updated_Location, Delivery_Status, Package_Type_ID, Delivery_Mode_ID, Origin_Address_ID, Destination_Address_ID, Customer_ID, Priority_ID, Service_Location_Zipcode, Shipment_ID, Warehouse_ID, Office_ID)
				VALUES (@Package_Weight, @Last_Updated_Location,'Order Placed', @Package_Type_ID, @Delivery_Mode_ID, @Origin_Address_ID, @Destination_Address_ID, @Customer_ID, @Priority_ID, @Service_Location_Zipcode, NULL, NULL, @Office_ID)

				SET @Package_ID = IDENT_CURRENT('Package')	
			COMMIT
			RETURN 1
		END

	END TRY

	BEGIN CATCH
		PRINT 'Error occured while inserting package details'
		ROLLBACK
		RETURN -99
	END CATCH
END
GO


----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--SP2 (usp_UpdateShipmentStatus) - Updates Shipment Status as 'Delayed' on condition that Current Date exceeds Expected Deleivery Date and Package is not yet Delivered

CREATE PROCEDURE usp_UpdateShipmentStatus
AS
BEGIN
	BEGIN TRY

		BEGIN TRAN
			UPDATE Shipment
			SET Shipment_Status = 'Delayed'
			WHERE Expected_Delivery_Date <  CAST(GETDATE() as DATE) AND Shipment_Status <> 'Delivered'
		COMMIT
		RETURN 1
	END TRY

	BEGIN CATCH
		PRINT 'Error occured while updating Shipment Status'
		ROLLBACK
		RETURN -99
	END CATCH
END
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--SP3 (usp_InsertPaymentDetailsForPackage) - Inserts Payment Details For Package using Package Id  and gives PaymentId as an output

CREATE PROCEDURE usp_InsertPaymentDetailsForPackage(
	@Package_ID INT,
	@Payment_Type_ID INT,
	@Payment_ID INT OUT
)
AS
BEGIN
	
	DECLARE @TotalAmount INT, @Priority_Type VARCHAR(20), @Package_Type_Name VARCHAR(30) , @Package_Weight NUMERIC(3,1)

	BEGIN TRY
		
		IF NOT EXISTS (SELECT Package_ID FROM Package WHERE Package_ID = @Package_ID)
		BEGIN
			RETURN -1
		END

		IF NOT EXISTS (SELECT Payment_Type_ID FROM Payment_Type WHERE Payment_Type_ID = @Payment_Type_ID)
		BEGIN
			RETURN -2
		END

		SELECT @Priority_Type = pr.Priority_Type FROM Package p INNER JOIN [Priority] pr On p.Priority_ID = pr.Priority_ID WHERE p.Package_ID = @Package_ID

		SELECT @Package_Type_Name = pt.Package_Type_Name FROM Package_Type pt INNER JOIN Package p ON pt.Package_Type_ID = p.Package_Type_ID where p.Package_ID = @Package_ID

		SELECT @Package_Weight = Package_Weight FROM Package WHERE Package_ID = @Package_ID

		SELECT @TotalAmount = dbo.udf_caluclatePackagePrice(@Priority_Type, @Package_Type_Name, @Package_Weight)

		BEGIN TRAN
			INSERT INTO Payments( Payment_Date, Total_Amount, Payment_Status ,Payment_Type_ID, Package_ID) VALUES (CAST(GETDATE() AS DATE), @TotalAmount, 'Pending',@Payment_Type_ID, @Package_ID)

			SET @Payment_ID = (SELECT Payment_ID FROM Payments WHERE Package_ID = @Package_ID)
		COMMIT
		RETURN 1
	END TRY

	BEGIN CATCH
		PRINT 'Error occured while Inserting Payment Details'
		ROLLBACK
		RETURN -99
	END CATCH
END
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--SP4 (usp_UpdatePackageDeliveryStatus) - Updates the status of the package and returns 1 for successful update

CREATE PROCEDURE usp_UpdatePackageDeliveryStatus(
	@Package_ID INT,
	@Delivery_Status VARCHAR(20)
)
AS
BEGIN
	BEGIN TRY
		
		IF NOT EXISTS (SELECT Package_ID FROM Package WHERE Package_ID = @Package_ID)
		BEGIN
			RETURN -1
		END

		IF @Delivery_Status NOT IN('Order Placed','Dispatched','In-Transit', 'Delivered','Cancelled','Delayed')
		BEGIN
			RETURN -2
		END

		BEGIN TRAN

			UPDATE Package
			SET Delivery_Status = @Delivery_Status WHERE Package_ID = @Package_ID

		COMMIT
		RETURN 1
	END TRY

	BEGIN CATCH
		PRINT 'Error occured while updating package detais'
		ROLLBACK
		RETURN -99
	END CATCH
END
GO

drop procedure usp_UpdatePackageDeliveryStatus

---------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------Stored Procedure Execution--------------------------------------------------------------------
-- SP1 (usp_InsertPackageDetails) Execution

--DECLARE @ReturnValue1 INT, @Package_ID INT
--EXEC @ReturnValue1 = usp_InsertPackageDetails 28,' 21 Bolyston', '428','250', '176', '179', '101', '152', '01031', '101', @Package_ID OUT
--SELECT @ReturnValue1 AS ReturnValue, @Package_ID AS PackageID
--GO

---------------------------------------------------------------------------------------------------------------------------------------------
-- SP2 (usp_UpdateShipmentStatus) Execution

--DECLARE @ReturnValue2 INT
--EXEC @ReturnValue2 = usp_UpdateShipmentStatus
--SELECT @ReturnValue2 AS ReturnValue
--GO

---------------------------------------------------------------------------------------------------------------------------------------------
-- SP3 (usp_InsertPaymentDetailsForPackage) Execution

--DECLARE @ReturnValue3 INT, @Payment_ID INT
--EXEC @ReturnValue3 = usp_InsertPaymentDetailsForPackage 1011, 51, @Payment_ID OUT
--SELECT @ReturnValue3 AS ReturnValue, @Payment_ID AS PaymentID
--GO

----------------------------------------------------------------------------------------------------------------------------------------------
-- SP4 (usp_UpdatePackageDeliveryStatus) Execution

--DECLARE @ReturnValue4 INT, @Package_ID INT, @Delivery_Status VARCHAR(20)
--EXEC @ReturnValue4 = usp_UpdatePackageDeliveryStatus 1008, 'In-Transit'
--SELECT @ReturnValue4 AS ReturnValue
--GO
