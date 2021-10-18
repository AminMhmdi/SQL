BEGIN TRY
    DROP FUNCTION dbo.[GetHoliday];
END TRY
BEGIN CATCH
    PRINT 'GetHoliday Function did not exist.';
END CATCH
GO
CREATE FUNCTION [dbo].[GetHoliday](@date datetime2)
RETURNS NVARCHAR(50)
AS
BEGIN
    declare @s NVARCHAR(50)

    SELECT @s = CASE
        --WHEN dbo.ShiftHolidayToWorkday('1400-01-01') = @date THEN N'جشن نوروز/جشن سال نو'
		WHEN [Month] = 1  AND [DayOfMonth] BETWEEN 1 AND 4 THEN N'عیدنوروز'
		WHEN [Month] = 1  AND [DayOfMonth] = 9 THEN N'ولادت حضرت قائم عجل الله تعالی فرجه و جشن نیمه شعبان'
		WHEN [Month] = 1  AND [DayOfMonth] = 12 THEN N'روز جمهوری اسلامی ایران'
		WHEN [Month] = 1  AND [DayOfMonth] = 13 THEN N'جشن سیزده به در'
		WHEN [Month] = 2  AND [DayOfMonth] = 14 THEN N'شهادت حضرت علی علیه السلام'
		WHEN [Month] = 2  AND [DayOfMonth] = 23 THEN N'عید سعید فطر'
		WHEN [Month] = 2  AND [DayOfMonth] = 24 THEN N'تعطیل به مناسبت عید سعید فطر'
		WHEN [Month] = 3  AND [DayOfMonth] = 14 THEN N'رحلت حضرت امام خمینی'
		WHEN [Month] = 3  AND [DayOfMonth] = 15 THEN N'قیام 15 خرداد'
		WHEN [Month] = 3  AND [DayOfMonth] = 16 THEN N'شهادت امام جعفر صادق علیه السلام'
		WHEN [Month] = 4  AND [DayOfMonth] = 30 THEN N'عید سعید قربان'
		WHEN [Month] = 5  AND [DayOfMonth] = 7 THEN N'عید سعید غدیر خم'
		WHEN [Month] = 5  AND [DayOfMonth] = 27 THEN N'تاسوعای حسینی'
		WHEN [Month] = 5  AND [DayOfMonth] = 28 THEN N'عاشورای حسینی'
		WHEN [Month] = 7  AND [DayOfMonth] = 5 THEN N'اربعین حسینی'
		WHEN [Month] = 7  AND [DayOfMonth] = 13 THEN N'رحلت رسول اکرم؛ شهادت امام حسن مجتبی علیه السلام'
		WHEN [Month] = 7  AND [DayOfMonth] = 15 THEN N'شهادت امام رضا علیه السلام'
		WHEN [Month] = 7  AND [DayOfMonth] = 23 THEN N'هادت امام حسن‌عسکری و آغاز امامت حضرت ولی‌عصر(عج)'
		WHEN [Month] = 8  AND [DayOfMonth] = 2 THEN N'میلاد رسول اکرم و امام جعفر صادق علیه السلام'
		WHEN [Month] = 10  AND [DayOfMonth] = 16 THEN N'شهادت حضرت فاطمه زهرا سلام الله علیها'
		WHEN [Month] = 11  AND [DayOfMonth] = 22 THEN N'پیروزی انقلاب اسلامی'
		WHEN [Month] = 11  AND [DayOfMonth] = 26 THEN N'ولادت امام علی علیه السلام و روز پدر'
		WHEN [Month] = 12  AND [DayOfMonth] = 10 THEN N'مبعث رسول اکرم'
		WHEN [Month] = 12  AND [DayOfMonth] = 27 THEN N'ولادت حضرت قائم (عج لالله تعالی) و روز جهانی مستضعفین'
		WHEN [Month] = 12  AND [DayOfMonth] = 29 THEN N'روز ملی شدن صنعت نفت ایران'
       
        ELSE NULL END
    FROM (
        SELECT
            [Year] = YEAR(@date),
            [Month] = MONTH(@date),
            [DayOfMonth] = DAY(@date),
            [DayName]   = DATENAME(weekday,@date)
    ) c

    RETURN @s
END
GO

select dbo.GetHoliday('1400-01-01')
--------------------------------------------------------------------------------------------------------------------
BEGIN TRY
    DROP FUNCTION dbo.GetHolidays;
END TRY
BEGIN CATCH
    PRINT 'GetHolidays Function did not exist.';
END CATCH
GO
CREATE FUNCTION [dbo].GetHolidays(@year int)
RETURNS TABLE 
AS
RETURN (  
    SELECT dt, dbo.GetHoliday(dt) as Holiday
    FROM (
        SELECT DATEADD(DAY, number,CAST(convert(varchar,@year) + '-01-01' AS datetime2)) dt
        FROM master..spt_values 
        WHERE  type='p' 
        ) d
    WHERE  year(dt) = @year and dbo.GetHoliday(dt) is not null
)
GO
SELECT * FROM [dbo].[GetHolidays] (1400)
--------------------------------------------------------------------------------------------------------------------
if not exists(SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE  TABLE_NAME = 'Holidays')
    CREATE table Holidays(DateOfHoliday datetime2 primary key clustered, Holiday NVARCHAR(50),HolidayInGregorian datetime2)
--------------------------------------------------------------------------------------------------------------------

INSERT INTO  Holidays(DateOfHoliday, Holiday,HolidayInGregorian)
    SELECT a.dt, a.Holiday , [dbo].[PersianToGregorian] (CONVERT(VARCHAR(10), a.dt, 111))
    FROM dbo.GetHolidays(1400) a
        left join Holidays b on b.DateOfHoliday = a.dt
    WHERE  b.DateOfHoliday is null
--------------------------------------------------------------------------------------------------------------------

BEGIN TRY
    DROP FUNCTION dbo.GetWorkDays;
END TRY
BEGIN CATCH
    PRINT 'GetWorkDays Function did not exist.';
END CATCH
GO
CREATE FUNCTION [dbo].[GetWorkDays](@StartDate varchar(10) = NULL, @EndDate varchar(10) = NULL)
RETURNS INT 
AS
BEGIN
DECLARE @StartDate2 DATE  = dbo.PersianToGregorian(@StartDate)
DECLARE @EndDate2 DATE   = dbo.PersianToGregorian(@EndDate)
DECLARE @Days int

    IF @StartDate IS NULL OR @EndDate IS NULL
        RETURN  0

    IF @StartDate >= @EndDate 
        RETURN  0

	--V2
    SET @Days = 0
	  SELECT 
	  @Days =  DATEDIFF(DAY, @StartDate2, @EndDate2)
      - (DATEDIFF(day, -3,  @EndDate2)/7-DATEDIFF(day, -2,  @StartDate2)/7)
      - (SELECT COUNT(DateOfHoliday) FROM Holidays WHERE  HolidayInGregorian >= @StartDate2 AND HolidayInGregorian <= @EndDate2 AND DATENAME(DW,[dbo].[PersianToGregorian] (CONVERT(VARCHAR(10), DateOfHoliday, 111))) NOT IN ('Friday'))
    RETURN  @Days
END
GO