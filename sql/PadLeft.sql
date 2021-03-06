USE [StartFrame]
GO
/****** Object:  UserDefinedFunction [dbo].[PadLeft]    Script Date: 05/09/2018 8:57:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Lic. Oscar Valente
-- Create date: 27-01-2011
-- Description:	Retorna una cadena completada a la izquierda con el caracter indicado
-- =============================================
ALTER FUNCTION [dbo].[PadLeft](@PadChar char(1), @PadToLen int, @BaseString varchar(100))
returns varchar(1000)

as

begin

  declare @Padded varchar(1000)
  declare @BaseLen int
  set @BaseLen = LEN(@BaseString)

  if @BaseLen >= @PadToLen
    set @Padded = @BaseString
  else
    set @Padded = REPLICATE(@PadChar, @PadToLen - @BaseLen) + @BaseString
    
  return @Padded
end



