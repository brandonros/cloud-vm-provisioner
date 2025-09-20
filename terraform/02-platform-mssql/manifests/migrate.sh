#!/bin/bash

# MSSQL Migration Script
# Usage: ./run-migration.sh

echo "Creating temporary migration pod..."

# Create a pod and execute the migration
kubectl run mssql-migration-pod \
  --image=mcr.microsoft.com/mssql-tools \
  --rm -i --tty \
  --namespace=mssql \
  --restart=Never \
  -- /bin/bash -c "
    # Wait for SQL Server to be ready
    echo 'Checking SQL Server connectivity...'
    until /opt/mssql-tools/bin/sqlcmd -S mssql -U sa -P 'Test_Password123!' -Q 'SELECT 1' &> /dev/null
    do
      echo 'Waiting for SQL Server...'
      sleep 5
    done
    
    echo 'SQL Server is ready. Running migrations...'
    
    # Create the SQL script file
    cat > /tmp/migration.sql << 'EOF'
-- Create database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'db')
CREATE DATABASE db;
GO

USE db;
GO

-- Create table with UUID as primary key
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Accounts')
CREATE TABLE Accounts (
  Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
  Name NVARCHAR(100),
  Email NVARCHAR(255) UNIQUE,
  CreatedAt DATETIME2 DEFAULT GETDATE(),
  UpdatedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- Create index on Id for better query performance
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Accounts_Id')
CREATE INDEX IX_Accounts_Id ON Accounts(Id);
GO

-- Create stored procedure to get account by UUID
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_GetAccountByUuid')
DROP PROCEDURE sp_GetAccountByUuid;
GO

CREATE PROCEDURE sp_GetAccountByUuid
  @AccountId UNIQUEIDENTIFIER
AS
BEGIN
  SET NOCOUNT ON;
  
  SELECT 
    Id,
    Name,
    Email,
    CreatedAt,
    UpdatedAt
  FROM Accounts 
  WHERE Id = @AccountId;
END
GO

-- Create stored procedure to create new account
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_CreateAccount')
DROP PROCEDURE sp_CreateAccount;
GO

CREATE PROCEDURE sp_CreateAccount
  @Name NVARCHAR(100),
  @Email NVARCHAR(255),
  @Id UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  
  SET @Id = NEWID();
  
  INSERT INTO Accounts (Id, Name, Email) 
  VALUES (@Id, @Name, @Email);
  
  SELECT 
    Id,
    Name,
    Email,
    CreatedAt,
    UpdatedAt
  FROM Accounts 
  WHERE Id = @Id;
END
GO

-- Create stored procedure to update account
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_UpdateAccount')
DROP PROCEDURE sp_UpdateAccount;
GO

CREATE PROCEDURE sp_UpdateAccount
  @AccountId UNIQUEIDENTIFIER,
  @Name NVARCHAR(100) = NULL,
  @Email NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  
  UPDATE Accounts 
  SET 
    Name = ISNULL(@Name, Name),
    Email = ISNULL(@Email, Email),
    UpdatedAt = GETDATE()
  WHERE Id = @AccountId;
  
  SELECT 
    Id,
    Name,
    Email,
    CreatedAt,
    UpdatedAt
  FROM Accounts 
  WHERE Id = @AccountId;
END
GO

-- Insert sample data with UUIDs
IF NOT EXISTS (SELECT * FROM Accounts)
BEGIN
  INSERT INTO Accounts (Id, Name, Email) VALUES 
    (NEWID(), 'John Doe', 'john@example.com'),
    (NEWID(), 'Jane Smith', 'jane@example.com'),
    (NEWID(), 'Bob Wilson', 'bob@example.com');
  
  -- Display inserted sample data
  PRINT 'Sample data inserted:';
  SELECT * FROM Accounts;
END
GO

PRINT 'Migration completed successfully!';
EOF
    
    # Run the migration script
    /opt/mssql-tools/bin/sqlcmd -S mssql -U sa -P 'Test_Password123!' -i /tmp/migration.sql
    
    if [ \$? -eq 0 ]; then
      echo 'Migration completed successfully!'
      echo 'Verifying migration...'
      /opt/mssql-tools/bin/sqlcmd -S mssql -U sa -P 'Test_Password123!' -d db -Q 'SELECT COUNT(*) as AccountCount FROM Accounts; SELECT * FROM Accounts;'
    else
      echo 'Migration failed!'
      exit 1
    fi
  "