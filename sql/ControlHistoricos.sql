USE [Gestion]
GO
/****** Object:  StoredProcedure [dbo].[_ControlHistoricos]    Script Date: 05/09/2018 9:13:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[_ControlHistoricos]
	@corregir bit = 0
	,@historicos bit = 0
AS
BEGIN

	print ''
	print 'Se controla (para los grupos TBCRA, TLEYES, TCNV, TCIMPR):'
	print '-Coherencia entre fechas desde/hasta de un mismo histórico'
	print '-Solapamiento de fechas entre períodos versionados'
	print '-Nro. de versión de un período contra la del período anterior'
	print '-Huecos entre versionados (para históricos mayores al 2/7/2007)'
	print '-Nro. de versión del capítulo vigente contra la del último histórico'
	print '-Fecha de vigencia del capítulo contra la del último histórico'
	if @historicos=1
		print '-Colisión entre el capítulo vigente y algún histórico en la misma posición del árbol'


	DECLARE 
		@cd_capitulo int
		,@nu_version int
		,@fe_vigencia_desde date
	DECLARE 
		@cd_capitulo_historico int
		,@nu_version_his int
		,@fe_vigencia_desde_his date
		,@fe_vigencia_hasta_his date
	DECLARE
		@nu_version_ant int
        ,@fe_desde_ant date
        ,@fe_hasta_ant date
	DECLARE
		@msgerr varchar(1000)
		,@cant int
		,@canthist int
		,@errores int
		,@tieneHistoria bit
		,@cd_capitulo_colision int

	--Control de errores
	DELETE _ReindexarHistoricos

	--Cursor de capítulos
	DECLARE capitulos_cursor CURSOR FAST_FORWARD READ_ONLY  FOR
		SELECT cd_capitulo, nu_version, fe_vigencia_desde
		FROM MGCapitulos
		WHERE st_estado = 'A'
			and cd_grupo IN('TBCRA', 'TLEYES', 'TCNV', 'TCIMPR')
		ORDER BY cd_capitulo

	OPEN capitulos_cursor

	--Primer registro
	FETCH NEXT FROM capitulos_cursor
		INTO @cd_capitulo, @nu_version, @fe_vigencia_desde

	SET @cant = 0
	SET @canthist = 0
	SET @errores = 0

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--DEBUG
		--print ''
		--print 'Procesando capítulo: ' + CAST(@cd_capitulo as varchar)
		
		SET @cant = @cant + 1
		SET @tieneHistoria = 0

		--Busca los históricos
		---------------------------------------------
			--Cursor de históricos de capítulos
			DECLARE historicos_cursor CURSOR FAST_FORWARD READ_ONLY  FOR
				SELECT cd_capitulo_historico, nu_version, fe_vigencia_desde, fe_vigencia_hasta
				FROM MGCapitulosHistoricos
				WHERE st_estado = 'A' and cd_capitulo = @cd_capitulo
				ORDER BY nu_version

			OPEN historicos_cursor

			--Primer registro
			FETCH NEXT FROM historicos_cursor
				INTO @cd_capitulo_historico, @nu_version_his, @fe_vigencia_desde_his, @fe_vigencia_hasta_his

			SET @nu_version_ant = 0
			SET @fe_desde_ant = null
			SET @fe_hasta_ant = null

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @canthist = @canthist + 1
				SET @tieneHistoria = 1

				--********** VALIDACIONES HISTORICOS **********
				--*********************************************
				SET @msgerr = ''

				--fecha desde-hasta
				IF @fe_vigencia_desde_his > @fe_vigencia_hasta_his BEGIN
					SET @msgerr = @msgerr + '   La fecha inicial (' + cast(@fe_vigencia_desde_his as varchar)
						+ ') debe ser menor o igual que la FINAL (' + + cast(@fe_vigencia_hasta_his as varchar) + ')'
						 + CHAR(13)
				END

				--números de versión histórica
				If @nu_version_ant <> 0 And @nu_version_his <= @nu_version_ant BEGIN
					SET @msgerr = @msgerr + '   La versión ' + cast(@nu_version_his as varchar) 
						+ ' es menor que la del período anterior (' + cast(@nu_version_ant as varchar) + ')'
						 + CHAR(13)
				END

				--controles cruzados
				If @fe_hasta_ant is not null begin
					--huecos entre versionados
					if @fe_vigencia_desde_his > '2007-07-02' begin
						if @fe_vigencia_desde_his <> dateadd(day, 1, @fe_hasta_ant) BEGIN
							SET @msgerr = @msgerr + '   La fecha inicial (' +  + cast(@fe_vigencia_desde_his as varchar)
								+ ') debe ser igual a la del período anterior + 1 día (' +  cast(dateadd(day, 1, @fe_hasta_ant) as varchar)
								+ ')' + CHAR(13)

							INSERT INTO _ReindexarHistoricos(cd_capitulo, cd_capitulo_historico, de_error)
								VALUES (NULL, @cd_capitulo_historico, @msgerr)

							IF @corregir=1 BEGIN
								UPDATE MGCapitulosHistoricos
									SET fe_vigencia_desde = dateadd(day, 1, @fe_hasta_ant)
									WHERE cd_capitulo_historico = @cd_capitulo_historico
								
								SET @msgerr = @msgerr + '   (corregido)'
							END
						END
					end else begin
						--fecha hasta_ant > desde
						If @fe_vigencia_desde_his <= @fe_hasta_ant BEGIN
							SET @msgerr = @msgerr + '   La fecha inicial (' +  + cast(@fe_vigencia_desde_his as varchar)
								+ ') debe ser mayor que la final del período anterior (' +  cast(@fe_hasta_ant as varchar)
								+ ')'  + CHAR(13)

							INSERT INTO _ReindexarHistoricos(cd_capitulo, cd_capitulo_historico, de_error)
								VALUES (NULL, @cd_capitulo_historico, @msgerr)

							IF @corregir=1 BEGIN
								UPDATE MGCapitulosHistoricos
									SET fe_vigencia_desde = dateadd(day, 1, @fe_hasta_ant)
									WHERE cd_capitulo_historico = @cd_capitulo_historico
								
								SET @msgerr = @msgerr + '   (corregido)'
							END
						END
					end
				
				end

				--**********************************

				IF @msgerr <> '' BEGIN
					SET @errores = @errores + 1

					print ''
					print 'Errores en capítulo ' + cast(@cd_capitulo as varchar) 
						+ ', histórico ' + cast(@cd_capitulo_historico as varchar) 
						+ ' (' + cast(@nu_version_his as varchar)
						+ '):'
					print @msgerr
				END

				--acumula período anterior
				set @nu_version_ant = @nu_version_his
				set @fe_desde_ant = @fe_vigencia_desde_his
				set @fe_hasta_ant = @fe_vigencia_hasta_his

				--Siguiente registro
				FETCH NEXT FROM historicos_cursor
					INTO @cd_capitulo_historico, @nu_version_his, @fe_vigencia_desde_his, @fe_vigencia_hasta_his
			END

			--Cierra el cursor de históricos del capítulo
			CLOSE historicos_cursor
			DEALLOCATE historicos_cursor
		---------------------------------------------

		--********** VALIDACIONES CAPITULO **********
		--*******************************************
		set @msgerr = ''
		IF @tieneHistoria = 1 begin
			--números de versión actual con el último histórico
			If @nu_version <= @nu_version_his BEGIN
				SET @msgerr = @msgerr + '   La versión actual ' + cast(@nu_version as varchar) 
					+ ' es menor o igual que la del último histórico (' + cast(@nu_version_his as varchar) 
					+ ')' + CHAR(13)
			END
					
			--hueco entre capítulo vigente y último versionado
			if @fe_vigencia_desde > '2007-07-02' begin
				if @fe_vigencia_desde <> dateadd(day, 1, @fe_vigencia_hasta_his) BEGIN
					SET @msgerr = @msgerr + '   La fecha de vigencia del capítulo (' +  + cast(@fe_vigencia_desde as varchar)
						+ ') debe ser igual a la del último histórico + 1 día (' +  cast(dateadd(day, 1, @fe_vigencia_hasta_his) as varchar)
						+ ')' + CHAR(13)

					INSERT INTO _ReindexarHistoricos(cd_capitulo, cd_capitulo_historico, de_error)
						VALUES (@cd_capitulo, NULL, @msgerr)

					IF @corregir=1 BEGIN
						UPDATE MGCapitulos
							SET fe_vigencia_desde = dateadd(day, 1, @fe_vigencia_hasta_his)
							WHERE cd_capitulo = @cd_capitulo
								
						SET @msgerr = @msgerr + '   (corregido)'
					END
				END
			end else begin
				--fecha vigencia actual > último histórico
				If @fe_vigencia_desde <= @fe_vigencia_hasta_his BEGIN
					SET @msgerr = @msgerr + '   La fecha de vigencia del capítulo (' +  + cast(@fe_vigencia_desde as varchar)
						+ ') debe ser mayor que la del último histórico (' +  cast(@fe_vigencia_hasta_his as varchar)
						+ ')'  + CHAR(13)
								
					INSERT INTO _ReindexarHistoricos(cd_capitulo, cd_capitulo_historico, de_error)
						VALUES (@cd_capitulo, NULL, @msgerr)

					IF @corregir=1 BEGIN
						UPDATE MGCapitulos
							SET fe_vigencia_desde = dateadd(day, 1, @fe_vigencia_hasta_his)
							WHERE cd_capitulo = @cd_capitulo

						SET @msgerr = @msgerr + '   (corregido)'
					END
				END
			end

			--colisión en la misma posición del árbol con algún histórico (de cualquier otro capítulo)
			if @historicos=1 begin
				SELECT @cd_capitulo_colision = h.cd_capitulo_historico 
					FROM MGCapitulosHistoricos h, MGCapitulos c
					WHERE c.cd_capitulo = @cd_capitulo		--capítulo vigente que está siendo controlado
						and h.cd_capitulo <> @cd_capitulo	--históricos de cualquier otro capítulo (mismo grupo, tema y posición del árbol, en el mismo período de tiempo)
						and h.cd_grupo = c.cd_grupo
						and h.cd_tema = c.cd_tema
						and h.fe_vigencia_hasta >= c.fe_vigencia_desde
						and h.nu_nivel1=c.nu_nivel1 and h.nu_nivel2=c.nu_nivel2 and h.nu_nivel3=c.nu_nivel3 and h.nu_nivel4=c.nu_nivel4 
						and h.nu_nivel5=c.nu_nivel5 and h.nu_nivel6=c.nu_nivel6 and h.nu_nivel7=c.nu_nivel7 and h.nu_nivel8=c.nu_nivel8  
						and h.nu_nivel9=c.nu_nivel9

				if @cd_capitulo_colision is not null begin
					SET @msgerr = @msgerr + '   Existe un histórico (' +  + cast(@cd_capitulo_colision as varchar)
						+ ') que ocupa la misma posición arbolar (grupo+tema+nivelN) en el mismo período de tiempo'
						+ ''  + CHAR(13)
				end
			end

			--**********************************

			IF @msgerr <> '' BEGIN
				SET @errores = @errores + 1

				print ''
				print 'Errores en capítulo vigente ' + cast(@cd_capitulo as varchar) + ':'
				print @msgerr
			END
		END

		--Siguiente registro
		FETCH NEXT FROM capitulos_cursor
			INTO @cd_capitulo, @nu_version, @fe_vigencia_desde
	END

	--Cierra el cursor de capítulos
	CLOSE capitulos_cursor
	DEALLOCATE capitulos_cursor

	print ''
	print 'Se procesaron ' + cast(@cant as varchar) + ' capítulos con ' + cast(@canthist as varchar) + ' históricos.'
	print ''
	print 'Se detectaron ' + cast(@errores as varchar) + ' registros con errores'

	--Retorno
	SELECT cd_capitulo = isnull(cd_capitulo, 0), 
		cd_capitulo_historico = isnull(cd_capitulo_historico, 0), 
		de_error
	FROM _ReindexarHistoricos

END