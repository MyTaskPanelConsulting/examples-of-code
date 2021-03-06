USE [Gestion]
GO
/****** Object:  StoredProcedure [dbo].[listasDS]    Script Date: 05/09/2018 9:18:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[listasDS]
@cd_lista _autonumerico, 
@nu_publicacion _cantidad,
@cd_grupo varchar(8)

as 

/*
Descripción: Devuelve un ds para indexar LISTAS.
 
Aplicación:  Indexador dtSearch. Manager

*/

begin

	--Marca los registros para indexar
	update LISTAS set st_indexar='I'
	--select * from Listas
	where st_indexar = 'S'
		
	--Actualiza los campos asociados a funciones SQL
	update LISTAS
	set ENLACE = dbo.[ENLACE_FUENTE_MBA](ls.FUENTE, ls.SDN_ID),
		IDENTIFICACION = dbo.[IDENTIFICACION_MBA](ls.FUENTE, ls.SDN_ID),
		CARGO_FUNCION = dbo.[CARGO_FUNCION_MBA](ls.FUENTE, ls.SDN_ID),
		INSTITUCION = dbo.[INSTITUCION_MBA](ls.FUENTE, ls.SDN_ID),
		FECHA_BAJA = dbo.[FECHA_BAJA_FUENTE_MBA](ls.FUENTE, ls.SDN_ID),
		FECHA_NAC = dbo.[FECHA_NAC_FUENTE_MBA](ls.FUENTE, ls.SDN_ID),
		SEXO = dbo.[SEXO_FUENTE_MBA](ls.FUENTE, ls.SDN_ID),
		DIRECCION_MODIFICADA = dbo.[DIRECCION_MODIFICADA_MBA](ls.FUENTE, ls.SDN_ID),
		IDTRIBUTARIA = np.IDTRIBUTARIA ,
		IDDOCUMENTO = np.IDDOCUMENTO 
	--select *
	from listas ls
		inner join INTNOMBRESPROD_MBA np on ls.FUENTE = np.FUENTE 
					and ls.SDN_ID = np.SDN_ID  
	where	st_indexar ='I'
		and st_estado = 'A';
			
			
	--Datos a Publicar
	with parientes (fuente, sdn_id, cantidad) 
	as(select FUENTE, SDN_ID, count(*)
			from INTVARIASPROD_MBA
			where INTERFACE='RELACION'
			group by FUENTE, SDN_ID
			having count(*)>0
	)
	select ls.cd_lista,
		LS.FUENTE, LS.SDN_ID, 0 as ALT_ID, ls.NOMBRE,
		ld.PAIS as  RESIDENCIA,
		isnull(pa.st_cooperante, 'S') as PC,
		case 
			when ls.IDTRIBUTARIA is null then 'null'
			when ls.IDTRIBUTARIA <> ls.IDdocumento then ls.IDTRIBUTARIA  
		else 'null'
		end as IDTRIBUTARIA ,
		isnull(ls.IDDOCUMENTO, 'null') as IDDOCUMENTO ,
		ls.ENLACE,
		ls.IDENTIFICACION,
		ls.CARGO_FUNCION,
		ls.INSTITUCION,
		ls.FECHA_BAJA,
		ls.FECHA_NAC,
		ls.SEXO,
		ld.DESCRIPCION as FUENTE_DESC,
		ld.DESC_CORTA as DESC_CORTA,
		ld.DESC_FILTRO as DESC_FILTRO,
		ld.TIPO_CONTENIDO as TIPO,
		ld.SUB_TIPO as SUB_TIPO,
		ld.CD_GRUPO as CD_GRUPO,
		CANTIDADRELACION = isnull(p.cantidad, 0),
		ls.DIRECCION_MODIFICADA as DIRECCIONMODIFICADA

	from LISTAS ls 
		left join parientes p on  p.FUENTE=ls.fuente 
			and ls.SDN_ID = p.SDN_ID 
        inner join LISTAS_DESCRIPCIONES ld  on ld.FUENTE  = ls.FUENTE  
		left join MBA_PAISES pa on cd_pais_alfa2 = ld.PAIS  
	 where 
		ls.st_indexar = 'I'
		and ls.st_estado = 'A'		
		and ld.CD_GRUPO = @cd_grupo
	
end