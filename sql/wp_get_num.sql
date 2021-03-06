USE [StartFrame]
GO
/****** Object:  StoredProcedure [dbo].[wp_get_num]    Script Date: 05/09/2018 8:57:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

/****** Objeto:  procedimiento almacenado dbo.wp_get_num    fecha de la secuencia de comandos: 02/11/2005 18:20:22 ******/
ALTER PROCEDURE [dbo].[wp_get_num] 

	@cd_talonario 	_codigo,
	@actualizar 	bit,
	@numero 	numeric(19,0) output,
	@prefijo 	char(2) output,
	@tipotalonario 	_lista output

AS

DECLARE @prox_num _autonumerico
DECLARE @db_id INT
DECLARE @db_nombre NVARCHAR(128)

SET @db_id = DB_ID()
SET @db_nombre = DB_NAME()

SET NOCOUNT ON

--Valida que exista el talonario

IF (SELECT COUNT(*) FROM wap_numauto WHERE cd_talonario = @cd_talonario) <> 0
   BEGIN
 	--Valida que no este bloqueado
	IF (SELECT st_bloqueado FROM wap_numauto WHERE cd_talonario = @cd_talonario ) = 0
	BEGIN
             BEGIN TRAN getnum
		--Bloquea el talonario
		UPDATE
			wap_numauto
		SET
			st_bloqueado = 1
		WHERE
			cd_talonario = @cd_talonario 

		--Asigna el valor
		SELECT @prox_num = va_numero + 1
		FROM wap_numauto WHERE cd_talonario = @cd_talonario
	
		IF @prox_num >= 9999999999999999998 SELECT @prox_num = 1

		--Actualiza el dato
		IF @actualizar = 1
			UPDATE 
				wap_numauto
			SET 
				va_numero = @prox_num
			WHERE 
				cd_talonario = @cd_talonario 
	
		UPDATE 
			wap_numauto
		SET 
			st_bloqueado = 0
		WHERE 
			cd_talonario = @cd_talonario 
	
		COMMIT TRAN getnum

		--Selecciona los datos de retorno
		SELECT @numero = @prox_num, @prefijo = va_prefijo, @tipotalonario = tp_talonario
		FROM wap_numauto
		WHERE cd_talonario = @cd_talonario
	
	END
	ELSE
		RAISERROR ('El registro se encuentra bloqueado.', 16, 1, @db_id, @db_nombre)
END
ELSE
	RAISERROR ('No existe el talonario: %s', 16, 1, @cd_talonario)

SET NOCOUNT OFF
