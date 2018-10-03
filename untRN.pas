unit untRN;

interface

uses
  System.Generics.Collections, untDAO, untCore, System.Rtti;

type

  TRN = class
  private

  protected
    FDAO: TDAO;

  public
    function insert(AModel: TModel): boolean; virtual;
    function update(AModel: TModel): boolean; virtual;
    function delete(AId: TValue): boolean; virtual;

    function select(AIndex: Integer): TModel; virtual;
    function list: TList<TModel>; overload; virtual;
    function list(AProperty: String; AValue: TValue): TList<TModel>; overload; virtual;
    
    constructor Create(AModelClass: TModelClass); virtual;
    destructor Destroy; virtual;
  end;

  TRNEmpresa = class(TRN)
  private
  public
    constructor Create; overload;
  end;

  TRNTanque = class(TRN)
  private
  public
    constructor Create; overload;
  end;

  TRNBomba = class(TRN)
  private
  public
    constructor Create; overload;
  end;

  TRNAbastecimento = class(TRN)
  private
  public
    constructor Create; overload;
  end;

implementation

uses
  System.SysUtils, untModels;

{ TRN }

constructor TRN.Create(AModelClass: TModelClass);
begin
  FDAO := TDAO.Create(AModelClass);
end;

function TRN.delete(AId: TValue): boolean;
begin
  Result := FDAO.delete(AId);
end;

destructor TRN.Destroy;
begin
  FreeAndNil(FDAO);
end;

function TRN.insert(AModel: TModel): boolean;
begin
  Result := FDAO.insert(AModel);
end;

function TRN.list: TList<TModel>;
begin
  Result := FDAO.list;
end;

function TRN.list(AProperty: String; AValue: TValue): TList<TModel>;
begin
  Result := FDAO.list(AProperty, AValue);
end;

function TRN.select(AIndex: Integer): TModel;
begin
  Result := FDAO.select(AIndex);
end;

function TRN.update(AModel: TModel): boolean;
begin
  Result := FDAO.update(AModel);
end;

{ TRNEmpresa }

constructor TRNEmpresa.Create;
begin
  Create(TEmpresa);
end;

{ TRNTanque }

constructor TRNTanque.Create;
begin
  Create(TTanque);
end;

{ TRNBomba }

constructor TRNBomba.Create;
begin
  Create(TBomba);
end;

{ TRNAbastecimento }

constructor TRNAbastecimento.Create;
begin
  Create(TAbastecimento);
end;

end.
