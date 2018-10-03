unit untDAO;


interface

uses
  System.Generics.Collections, FireDAC.Comp.Client, untORM,
  System.Rtti;

type

  TDAO = class
  private
    FManager: TModelManager;
  public
    property Manager: TModelManager read FManager write FManager;

    function insert(AModel: TModel): boolean; virtual;
    function update(AModel: TModel): boolean; virtual;
    function delete(AId: TValue): boolean; virtual;
    function select(AIndex: Integer): TModel; virtual;
    function list: TList<TModel>; overload; virtual;
    function list(AProperty: String; AValue: TValue): TList<TModel>; overload; virtual;

    constructor Create(AModelClass: TModelClass);
  end;

implementation

uses
  System.SysUtils, untEntity, untDMConnection;

{ TDAO }

constructor TDAO.Create(AModelClass: TModelClass);
begin
  FManager := TControleModelManager.Instance.getModelManager(AModelClass);
end;

function TDAO.delete(AId: TValue): boolean;
begin
  Result := Manager.Remove(AId);
end;

function TDAO.insert(AModel: TModel): boolean;
begin
  Result := Manager.Save(TModel(AModel));
end;

function TDAO.list: TList<TModel>;
begin
  try
    Result := Manager.All();
  except
    on E: Exception do
      raise Exception.Create('Error ao listar os registros. ' + #13 + E.message);
  end;
end;

function TDAO.list(AProperty: String; AValue: TValue): TList<TModel>;
begin
  try
    Result := Manager.list(AProperty, AValue);
  except
    on E: Exception do
      raise Exception.Create('Error ao listar os registros.' + #13 + E.message);
  end;
end;

function TDAO.select(AIndex: Integer): TModel;
begin
  try
    Result := Manager.Get('id', AIndex);
  except
    on E: Exception do
      raise Exception.Create('Error ao selecionar registro. ' + #13 + E.message);
  end;
end;

function TDAO.update(AModel: TModel): boolean;
begin
  try
    Result := Manager.Save(AModel);
  except
    on E: Exception do
      raise Exception.Create('Error ao listar os registros. ' + #13 + E.message);
  end;
end;

end.

