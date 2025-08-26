-- 1. Tạo Database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'QLCongViec')
BEGIN
    CREATE DATABASE QLCongViec;
END;
GO

USE QLCongViec;
GO

-- ===================================================
-- 2. Bảng Users
-- ===================================================
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Role NVARCHAR(20) CHECK (Role IN ('Admin','Leader','Member')) DEFAULT 'Member',
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 DEFAULT SYSDATETIME()
);
GO

-- ===================================================
-- 3. Bảng Projects
-- ===================================================
CREATE TABLE Projects (
    ProjectID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    StartDate DATE,
    EndDate DATE,
    Status NVARCHAR(20) CHECK (Status IN ('Planning','InProgress','Completed','OnHold')) DEFAULT 'Planning',
    CreatedBy INT NOT NULL,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Project_User FOREIGN KEY (CreatedBy) 
        REFERENCES Users(UserID) ON DELETE NO ACTION
);
GO

-- ===================================================
-- 4. Bảng ProjectMembers
-- ===================================================
CREATE TABLE ProjectMembers (
    MemberID INT IDENTITY(1,1) PRIMARY KEY,
    ProjectID INT NOT NULL,
    UserID INT NOT NULL,
    Role NVARCHAR(20) DEFAULT 'Member',
    JoinedAt DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_PM_Project FOREIGN KEY (ProjectID) 
        REFERENCES Projects(ProjectID) ON DELETE CASCADE,
    CONSTRAINT FK_PM_User FOREIGN KEY (UserID) 
        REFERENCES Users(UserID) ON DELETE NO ACTION
);
GO

-- ===================================================
-- 5. Bảng Tasks
-- ===================================================
CREATE TABLE Tasks (
    TaskID INT IDENTITY(1,1) PRIMARY KEY,
    ProjectID INT NOT NULL,
    AssignedTo INT NULL,
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    Status NVARCHAR(20) CHECK (Status IN ('Todo','InProgress','Review','Done')) DEFAULT 'Todo',
    Priority NVARCHAR(20) CHECK (Priority IN ('Low','Medium','High')) DEFAULT 'Medium',
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 DEFAULT SYSDATETIME(),
    DueDate DATETIME2 NULL,
    CONSTRAINT FK_Tasks_Project FOREIGN KEY (ProjectID) 
        REFERENCES Projects(ProjectID) ON DELETE CASCADE,
    CONSTRAINT FK_Tasks_User FOREIGN KEY (AssignedTo) 
        REFERENCES Users(UserID) ON DELETE SET NULL
);
GO

-- ===================================================
-- 6. Bảng Comments
-- ===================================================
CREATE TABLE Comments (
    CommentID INT IDENTITY(1,1) PRIMARY KEY,
    TaskID INT NOT NULL,
    UserID INT NOT NULL,
    Content NVARCHAR(MAX) NOT NULL,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Comments_Task FOREIGN KEY (TaskID) 
        REFERENCES Tasks(TaskID) ON DELETE CASCADE,
    CONSTRAINT FK_Comments_User FOREIGN KEY (UserID) 
        REFERENCES Users(UserID) ON DELETE NO ACTION
);
GO

-- ===================================================
-- 7. Bảng Files
-- ===================================================
CREATE TABLE Files (
    FileID INT IDENTITY(1,1) PRIMARY KEY,
    TaskID INT NOT NULL,
    FilePath NVARCHAR(255) NOT NULL,
    UploadedBy INT NOT NULL,
    UploadedAt DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Files_Task FOREIGN KEY (TaskID) 
        REFERENCES Tasks(TaskID) ON DELETE CASCADE,
    CONSTRAINT FK_Files_User FOREIGN KEY (UploadedBy) 
        REFERENCES Users(UserID) ON DELETE NO ACTION
);
GO

-- ===================================================
-- 8. Bảng TaskHistory
-- ===================================================
CREATE TABLE TaskHistory (
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    TaskID INT NOT NULL,
    ChangedBy INT NOT NULL,
    ChangedField NVARCHAR(100),
    OldValue NVARCHAR(255),
    NewValue NVARCHAR(255),
    ChangedAt DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_History_Task FOREIGN KEY (TaskID) 
        REFERENCES Tasks(TaskID) ON DELETE CASCADE,
    CONSTRAINT FK_History_User FOREIGN KEY (ChangedBy) 
        REFERENCES Users(UserID) ON DELETE NO ACTION
);
GO

-- ===================================================
-- 9. Bảng ActivityLogs
-- ===================================================
CREATE TABLE ActivityLogs (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    Action NVARCHAR(255) NOT NULL,
    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Logs_User FOREIGN KEY (UserID) 
        REFERENCES Users(UserID) ON DELETE CASCADE
);
GO

-- =======================================
-- Trigger: Cập nhật UpdatedAt khi UPDATE
-- =======================================

-- 1. Users
CREATE TRIGGER trg_Users_Update
ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE U
    SET UpdatedAt = SYSDATETIME()
    FROM Users U
    INNER JOIN Inserted I ON U.UserID = I.UserID;
END;
GO

-- 2. Projects
CREATE TRIGGER trg_Projects_Update
ON Projects
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE P
    SET UpdatedAt = SYSDATETIME()
    FROM Projects P
    INNER JOIN Inserted I ON P.ProjectID = I.ProjectID;
END;
GO

-- 3. ProjectMembers (nếu bạn muốn theo dõi UpdatedAt thì cần thêm cột này, hiện chưa có)
-- ALTER TABLE ProjectMembers ADD UpdatedAt DATETIME2 DEFAULT SYSDATETIME();
-- CREATE TRIGGER trg_ProjectMembers_Update
-- ON ProjectMembers
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE PM
--     SET UpdatedAt = SYSDATETIME()
--     FROM ProjectMembers PM
--     INNER JOIN Inserted I ON PM.ProjectID = I.ProjectID AND PM.UserID = I.UserID;
-- END;
-- GO

-- 4. Tasks
CREATE TRIGGER trg_Tasks_Update
ON Tasks
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE T
    SET UpdatedAt = SYSDATETIME()
    FROM Tasks T
    INNER JOIN Inserted I ON T.TaskID = I.TaskID;
END;
GO

-- 5. Comments (chỉ có CreatedAt, chưa có UpdatedAt → có thể thêm nếu cần)
-- ALTER TABLE Comments ADD UpdatedAt DATETIME2 DEFAULT SYSDATETIME();
-- CREATE TRIGGER trg_Comments_Update
-- ON Comments
-- AFTER UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE C
--     SET UpdatedAt = SYSDATETIME()
--     FROM Comments C
--     INNER JOIN Inserted I ON C.CommentID = I.CommentID;
-- END;
-- GO

-- 6. FileAttachments (hiện cũng chỉ có UploadedAt → có thể thêm UpdatedAt nếu muốn)
-- ALTER TABLE FileAttachments ADD UpdatedAt DATETIME2 DEFAULT SYSDATETIME();

-- 7. Notifications (chỉ có CreatedAt, chưa có UpdatedAt)

-- 8. TaskHistory (chỉ có ChangedAt → không cần UpdatedAt vì mỗi thay đổi là một bản ghi mới)

-- 9. ActivityLogs (chỉ có CreatedAt → không cần UpdatedAt)
