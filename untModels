{***************************************************************************************************************************************
  TTableAttribute: Usado para vincular a model a table do db.
  
  TFieldsAttribute> Usado para vincular o atributo ao field da table.
  
  TAssociationFieldAttribute: Usado para relacionamento do tipo FK.
  
  TProxyModel: Usado para não carregar os dados sem necessidade do tipo relacionamento na hora de acessar o object que possui 
  relacionamentos, evitando muita carga de dados.  
***************************************************************************************************************************************}

unit untModels;

interface

uses
  untORM;

type

  [TTableAttribute('tb_empresa')]
  TEmpresa = class(TModel)
  private
    [TFieldAttribute('cnpj')]
    FCnpj: String;

    [TFieldAttribute('descricao')]
    FDescricao: String;

    [TFieldAttribute('contato')]
    FContato: String;

    [TFieldAttribute('endereco')]
    FEndereco: String;

  public
    property Cnpj: String read FCnpj write FCnpj;
    property Descricao: String read FDescricao write FDescricao;
    property Contato: String read FContato write FContato;
    property Endereco: String read FEndereco write FEndereco;

  end;

  [TTableAttribute('tb_tanque')]
  TTanque = class(TModel)
  private
    [TFieldAttribute('codigo')]
    FCodigo: String;

    [TFieldAttribute('descricao')]
    FDescricao: String;

    [TFieldAttribute('tipo')]
    FTipo: Integer;

    [TAssociationFieldAttribute('id_empresa')]
    FEmpresa: TProxyModel<TEmpresa>;

    function GetEmpresa: TEmpresa;
    procedure SetEmpresa(const Value: TEmpresa);

  public
    property Codigo: String read FCodigo write FCodigo;
    property Descricao: String read FDescricao write FDescricao;
    property Tipo: Integer read FTipo write FTipo;
    property Empresa: TEmpresa read GetEmpresa write SetEmpresa;

    constructor create(); override;
  end;

  [TTableAttribute('tb_bomba')]
  TBomba = class(TModel)
  private
    [TFieldAttribute('codigo')]
    FCodigo: String;

    [TFieldAttribute('descricao')]
    FDescricao: String;

    [TAssociationFieldAttribute('id_tanque')]
    FTanque: TProxyModel<TTanque>;

    function GetTanque: TTanque;
    procedure SetTanque(const Value: TTanque);

  public
    property Codigo: String read FCodigo write FCodigo;
    property Descricao: String read FDescricao write FDescricao;
    property Tanque: TTanque read GetTanque write SetTanque;

    constructor create(); override;

  end;

  [TTableAttribute('tb_abastecimento')]
  TAbastecimento = class(TModel)
  private
    [TFieldAttribute('codigo')]
    FCodigo: String;

    [TFieldAttribute('quantidade_litros')]
    FQuantidadeLitros: Double;

    [TFieldAttribute('valor')]
    FValor: Currency;

    [TFieldAttribute('data')]
    FData: TDateTime;

    [TAssociationFieldAttribute('id_bomba')]
    FBomba: TProxyModel<TBomba>;

    function GetBomba: TBomba;
    procedure SetBomba(const Value: TBomba);

  public

    property Codigo: String read FCodigo write FCodigo;
    property QuantidadeLitros: Double read FQuantidadeLitros write FQuantidadeLitros;
    property Valor: Currency read FValor write FValor;
    property Data: TDateTime read FData write FData;
    property Bomba: TBomba read GetBomba write SetBomba;

    constructor create(); override;

  end;

implementation

uses
  System.SysUtils;

{ TAbastecimento }

constructor TAbastecimento.create;
begin
  inherited;
  FBomba := TProxyModel<TBomba>.create;
end;

function TAbastecimento.GetBomba: TBomba;
begin
  Result := FBomba.Value;
end;

procedure TAbastecimento.SetBomba(const Value: TBomba);
begin
  FBomba.Value := Value;
end;

{ TBomba }

constructor TBomba.create;
begin
  inherited;
  FTanque := TProxyModel<TTanque>.create;
end;

function TBomba.GetTanque: TTanque;
begin
  Result := FTanque.Value;
end;

procedure TBomba.SetTanque(const Value: TTanque);
begin
  FTanque.Value := Value;
end;

{ TTanque }

constructor TTanque.create;
begin
  inherited;
  FEmpresa := TProxyModel<TEmpresa>.create;
end;

function TTanque.GetEmpresa: TEmpresa;
begin
  Result := FEmpresa.Value;
end;

procedure TTanque.SetEmpresa(const Value: TEmpresa);
begin
  FEmpresa.Value := Value;
end;

end.

