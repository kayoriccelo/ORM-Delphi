unit untCore;

interface

uses
  System.Rtti, classes, Generics.Collections, FireDAC.Comp.Client,
  System.SysUtils, System.TypInfo;

resourcestring
  SQLSelect = 'SELECT %s FROM %s WHERE %s = %s';
  SQLSequence = 'SELECT NEXT VALUE FOR %s FROM RDB$DATABASE;';
  SQLInsert = 'INSERT INTO %s (%s) VALUES (%s)';
  SQLRemove = 'DELETE FROM %s WHERE %s = %s';
  SQLUpdate = 'UPDATE %s SET %s WHERE %s';

type
  TModel = class;
  TModelManager = class;
  TProxyModel<T: class> = class;
  TFieldAttribute = class;
  TModelField = class;
  TModelUtils = class;
  TModelSqlExpression = class;
  TAssociationModelField = class;
  TConexao = class;

  TModelClass = class of TModel;
  TFieldClass = class of TModelField;

  eTipoField = (tfiNormal, tfiEnumerator, tfiAssociacao, tfiMultiAssociacao);
  eTipoProject = (etpProducao, etpTest);

  TFieldAttribute = class(TCustomAttribute)
  private
    FFieldName: string;
  public
    property FieldName: string read FFieldName;
    constructor create(const AFieldName: string); virtual;
  end;

  TAssociationFieldAttribute = class(TFieldAttribute)
  private
  public
  end;

  TOneToOneFieldAttribute = class(TFieldAttribute)
  private
  public
  end;

  TManyToManyFieldAttribute = class(TFieldAttribute)
  private
  public
  end;

  TTableAttribute = class(TCustomAttribute)
  private
    FTableName: string;
  public
    property TableName: string read FTableName;
    constructor create(const ATableName: string); virtual;
  end;

  TModel = class
  private
    FObjects: TModelManager;
    function GetId: integer;
  protected
    [TFieldAttribute('id')]
    FId: integer;
  published
    property Id: integer read FId write FId;
  public
    // Orm
    property Objects: TModelManager read FObjects;

    function Save: boolean;
    function Refresh: boolean;
    function Remove: boolean;
    constructor create; overload; virtual;
    constructor create(AId: integer); overload; virtual;
    destructor destroy; override;
  end;

  TProxyModel<T: class> = class
  private
    FValue: T;
    FKey: integer;
    FFieldKey: string;
    FLoaded: boolean;
    FManyAssociation: boolean;
    function GetValue: T;
    function Changed: boolean;
    function GetAvailable: boolean;
    procedure SetValue(const Value: T);
  protected
    procedure Load; virtual;
  public
    property Key: integer read FKey write FKey;
    property Value: T read GetValue write SetValue;
    property Available: boolean read GetAvailable;
    procedure SetInitialValue(AValue: T);
    procedure DestroyValue;
    constructor create(AFieldKey: String = 'Id'; AManyAssociation: boolean = False);
  end;

  TModelManager = class
  private
    FClass: TModelClass;
    FTableName: string;
    FSqlExpression: TModelSqlExpression;

    FModelFields: TObjectList<TModelField>;
    FForeignFields: TObjectList<TModelField>;
    FRttiTypes: TObjectList<TRttiType>;

    procedure GetModelFields;

    function instanciar: TModel;
    function doGet(AModel: TModel; AQuery: TFDQuery = nil): TModel;
    function doSet(AModel: TModel; AQuery: TFDQuery): TModel;
    function doSave(AModel: TModel): boolean;
    function doUpdate(AModel: TModel): boolean;
    function GetSequenceName: string;
  protected
    property ModelFields: TObjectList<TModelField> read FModelFields;
    property ForeignFields: TObjectList<TModelField> read FForeignFields;

    procedure genIdValue(AModel: TModel);
    function getField(AFieldName: string): TModelField;
    function getSQLUpdate(AKey: integer): String;

  public
    property TableName: string read FTableName;
    property SequenceName: string read GetSequenceName;

    function Get(AKey: string; AValue: TValue): TModel;
    function List(AKey: string; AValue: TValue): TObjectList<TModel>;
    function All: TObjectList<TModel>;
    function Save(var AModel: TModel): boolean;
    function Remove(AId: TValue): boolean;

    constructor create(AClass: TModelClass); overload;
    constructor create(AModel: TModel); overload;
  end;

  TModelSqlExpression = class
  private
    FModelManager: TModelManager;
    FConexao: TConexao;
    function getSQLArguments(AArgumentString: string): String;
  public
    property Conexao: TConexao read FConexao write FConexao;

    function getLoadQuery(ASql: String): TFDQuery; overload;
    function getQuery(ASql: String): TFDQuery; overload;

    function getSQLFields: String;
    function getSQLParams: String;
    function getSQLFieldsValues: String;
    function getSQLSequence: string;

    function getSQLSelect(): String; overload;
    function getSQLInsert(): String; overload;
    function getSQLSelect(AKey: String; AValue: TValue): String; overload;
    function getSQLUpdate(AKey: String = '1'; AValue: String = '1'): String; overload;
    function getSQLRemove(AKey: String; AValue: TValue): string; overload;
    constructor create(AModelManager: TModelManager);
  end;

  TModelField = class
  private
    FValue: TValue;
    FFieldName: String;
    FAttibuteName: String;

    Contexto: TRttiContext;
    Tipo: TRttiType;

  protected
    function GetValue(AModel: TModel): TValue; virtual;
    procedure SetValue(AModel: TModel; AValue: TValue); virtual;
  public
    property FieldName: String read FFieldName;
    property AttibuteName: String read FAttibuteName;
    constructor create(const APropField: TRttiField; const AFieldAttribute: TFieldAttribute); virtual;
  end;

  TAssociationModelField = class(TModelField)
  private
  protected
    function GetValue(AModel: TModel): TValue; override;
    procedure SetValue(AModel: TModel; AValue: TValue); override;
  public
  end;

  TOneToOneModelField = class(TAssociationModelField)
  end;

  TManyToManyModelField = class(TAssociationModelField)
  end;

  TControleModelManager = class
  private
  var
    FDictModelManagers: TDictionary<TModelClass, TModelManager>;

    class var FInstance: TControleModelManager;
  protected
  public
    class function Instance: TControleModelManager;
    function getModelManager(AModelClass: TModelClass): TModelManager;
    constructor create;
  end;

  TModelUtils = class
  public
    class function getRttiClass(AClass: TModelClass): TRttiInstanceType; overload;
    class function getRttiClass(AClassString: string): TRttiInstanceType; overload;
  end;

  TConexao = class
  private

  public
    function abrirQuery(ASql: String): TFDQuery;
    function criarQuery(ASql: String): TFDQuery;
    
    constructor create(AConn: TFDConnection);

  end;

implementation

uses
  CodeSiteLogging, Data.DB;

{ TModel }

constructor TModel.create;
begin
  // FModelFields := TObjectList<TModelField>.Create;
  // instanciarFields;
  FObjects := TControleModelManager.Instance.getModelManager(TModelClass(Self.Classtype));
end;

constructor TModel.create(AId: integer);
begin
  create;
end;

destructor TModel.destroy;
begin
  // FreeAndNil(FModelFields);
  inherited;
end;

function TModel.GetId: integer;
begin
  // result := FId.Value;
end;

function TModel.Refresh: boolean;
begin
  Result := True;

  try
    Self := Objects.Get('id', Id);
  except
    Result := False;
  end;
end;

function TModel.Remove: boolean;
begin
  Result := True;

  try
    Objects.Remove(Self);
  except
    Result := False;
  end;
end;

function TModel.Save: boolean;
begin
  Result := True;

  try
    Objects.Save(Self);
  except
    Result := False;
  end;
end;

{ TModelManager }

function TModelManager.All: TObjectList<TModel>;
var
  loSql: String;
  loObject: TModel;
  FQuery: TFDQuery;
  i: integer;
begin
  Result := nil;
  loSql := FSqlExpression.getSQLSelect;
  try
    FQuery := FSqlExpression.getLoadQuery(loSql);
    FQuery.OffLine;

    Result := TObjectList<TModel>.create;
    for i := 1 to FQuery.RecordCount do
    begin
      FQuery.RecNo := i;
      loObject := TModel(instanciar);
      Result.add(doGet(loObject, FQuery));
    end;

  finally
    FQuery.Free;
    if (Result = nil) then
      loObject.Free;
  end;
end;

constructor TModelManager.create(AModel: TModel);
begin
  create(TModelClass(AModel.Classtype));
end;

constructor TModelManager.create(AClass: TModelClass);
begin
  FClass := AClass;
  FModelFields := TObjectList<TModelField>.create;
  FForeignFields := TObjectList<TModelField>.create;
  FRttiTypes := TObjectList<TRttiType>.create;
  if ModelFields.Count = 0 then
    GetModelFields;
  FSqlExpression := TModelSqlExpression.create(Self);
end;

function TModelManager.doGet(AModel: TModel; AQuery: TFDQuery): TModel;
var
  loField: TModelField;
begin
  Result := nil;
  try
    ModelFields.Clear;
    GetModelFields;

    for loField in ModelFields do
      if AQuery.FieldByName(loField.FieldName).DataType = ftTimeStamp then
        loField.SetValue(AModel, TValue.FromVariant(AQuery.FieldByName(loField.FieldName).AsDateTime))
      else
        loField.SetValue(AModel, TValue.FromVariant(AQuery.FieldByName(loField.FieldName).Value));

    for loField in ForeignFields do
      loField.SetValue(AModel, TValue.FromVariant(AQuery.FieldByName('id').Value));
  finally
    Result := AModel;
  end;
end;

function TModelManager.doSave(AModel: TModel): boolean;
var
  FQuery: TFDQuery;
  loSql: String;
begin
  // Sistema.conexao.ControleTransaction.BeginTransaction;
  loSql := FSqlExpression.getSQLInsert;
  try
    try
      genIdValue(AModel);
      FQuery := FSqlExpression.getQuery(loSql);
      doSet(AModel, FQuery);
      FQuery.ExecSQL;

      // Sistema.conexao.ControleTransaction.commit;
      codesite.send('Insert', FQuery.SQL.Text);
      codesite.send('Modelo salvo!', AModel);
    except
      on E: Exception do
      begin
        codesite.SendError('Error ao inserir registro.' + #13 + E.message);
        raise Exception.create('Error ao inserir registro.' + #13 + E.message);
      end
      // Sistema.conexao.ControleTransaction.rollBack;
    end;
  finally

    // Sistema.conexao.ControleTransaction.endTransaction;
  end;
end;

function TModelManager.doSet(AModel: TModel; AQuery: TFDQuery): TModel;
var
  loField: TModelField;
begin
  Result := nil;
  try
    for loField in ModelFields do
      AQuery.ParamByName('p_' + loField.FieldName).Value := loField.GetValue(AModel).asVariant;

    // for loField in ForeignFields do
    // AQuery.ParamByName('par_'+loField.FieldName).Value := loField.GetValue(AModel);
  finally
    Result := AModel;
  end;
end;

function TModelManager.doUpdate(AModel: TModel): boolean;
var
  FQuery: TFDQuery;
  loSql: String;
begin
  // Sistema.conexao.ControleTransaction.BeginTransaction;
  loSql := FSqlExpression.getSQLUpdate('id', AModel.Id.ToString);
  try
    try
      FQuery := FSqlExpression.getQuery(loSql);
      doSet(AModel, FQuery);
      FQuery.ExecSQL;
      // Sistema.conexao.ControleTransaction.commit;
      codesite.send('Update', FQuery.SQL.Text);
    except
      on E: Exception do
      begin
        codesite.SendError('Error ao alterar registro.' + #13 + E.message);
        raise Exception.create('Error ao alterar registro.' + #13 + E.message);
      end;
      // Sistema.conexao.ControleTransaction.rollBack;
    end;
  finally

    // Sistema.conexao.ControleTransaction.endTransaction;
  end;
end;

procedure TModelManager.genIdValue(AModel: TModel);
var
  FQuery: TFDQuery;
  loSql: String;
begin
  loSql := FSqlExpression.getSQLSequence;
  try
    FQuery := FSqlExpression.getLoadQuery(loSql);

    if FQuery.isEmpty then
      raise Exception.create('Não foi possível gerar sequencial da tabela.');

    getField('Id').SetValue(AModel, TValue.FromVariant(FQuery.FieldByName('GEN_ID').Value));

  finally
    FQuery.Free;
  end;

end;

function TModelManager.Get(AKey: string; AValue: TValue): TModel;
var
  loObject: TModel;
  FQuery: TFDQuery;
  loSql: String;
begin
  Result := nil;
  loSql := FSqlExpression.getSQLSelect(AKey, AValue);
  try
    FQuery := FSqlExpression.getLoadQuery(loSql);

    if FQuery.isEmpty then
      exit;

    loObject := TModel(instanciar);
    Result := doGet(loObject, FQuery);

  finally
    FQuery.Free;
  end;
end;

function TModelManager.getField(AFieldName: string): TModelField;
var
  loField: TModelField;
begin
  Result := nil;
  for loField in ModelFields do
    if lowercase(loField.FieldName) = lowercase(AFieldName) then
      exit(loField);
end;

procedure TModelManager.GetModelFields;
var
  Contexto: TRttiContext;
  Tipo: TRttiType;
  loField: TRttiField;
  loAttribute: TCustomAttribute;
begin
  try
    Contexto := TRttiContext.create;
    Tipo := Contexto.GetType(FClass.ClassInfo);
    for loAttribute in Tipo.GetAttributes do
      if loAttribute is TTableAttribute then
        FTableName := TTableAttribute(loAttribute).TableName;

    for loField in Tipo.GetFields do
    begin
      for loAttribute in loField.GetAttributes do
        if loAttribute is TManyToManyFieldAttribute then
          ForeignFields.add(TManyToManyModelField.create(loField, TManyToManyFieldAttribute(loAttribute)))
        else if loAttribute is TOneToOneFieldAttribute then
          ForeignFields.add(TOneToOneModelField.create(loField, TOneToOneFieldAttribute(loAttribute)))
        else if loAttribute is TAssociationFieldAttribute then
          ModelFields.add(TAssociationModelField.create(loField, TAssociationFieldAttribute(loAttribute)))
        else if loAttribute is TFieldAttribute then
          ModelFields.add(TModelField.create(loField, TFieldAttribute(loAttribute)));
    end;
  finally
    // Contexto.Free;
  end;
end;

function TModelManager.GetSequenceName: string;
begin
  Result := Format('%s_ID_GEN', [UpperCase(TableName)]);
end;

function TModelManager.getSQLUpdate(AKey: integer): String;
var
  loField: TModelField;
  loFields: TStrings;
begin

end;

function TModelManager.instanciar: TModel;
var
  loRttiContext: TRttiContext;
  loRttiType: TRttiInstanceType;
begin
  loRttiType := loRttiContext.FindType(FClass.unitName + '.' + FClass.ClassName) as TRttiInstanceType;
  if (loRttiType = nil) then
    raise Exception.create(Format('Modelo não encontrado pelo RTTI - %s.%s', [FClass.unitName, FClass.ClassName]));

  Result := TModel(loRttiType.GetMethod('Create').Invoke(loRttiType.MetaclassType, []).AsObject);
end;

function TModelManager.List(AKey: string; AValue: TValue): TObjectList<TModel>;
var
  loSql: String;
  loObject: TModel;
  FQuery: TFDQuery;
  i: integer;
begin
  Result := nil;
  loSql := FSqlExpression.getSQLSelect(AKey, AValue);
  try
    FQuery := FSqlExpression.getLoadQuery(loSql);
    FQuery.OffLine;

    Result := TObjectList<TModel>.create;
    for i := 1 to FQuery.RecordCount do
    begin
      FQuery.RecNo := i;
      loObject := TModel(instanciar);
      Result.add(doGet(loObject, FQuery));
    end;

  finally
    FQuery.Free;
    if (Result = nil) then
      loObject.Free;
  end;
end;

function TModelManager.Remove(AId: TValue): boolean;
var
  FQuery: TFDQuery;
  loSql: String;
begin
  // Sistema.conexao.ControleTransaction.BeginTransaction;
  loSql := FSqlExpression.getSQLRemove('id', AId);
  try
    try
      FQuery := FSqlExpression.getQuery(loSql);
      FQuery.ExecSQL;

      // Sistema.conexao.ControleTransaction.commit;
      codesite.send('Remove', FQuery.SQL.Text);
    except
      on E: Exception do
      begin
        codesite.SendError('Error ao deletar registro.' + #13 + E.message);
        raise Exception.create('Error ao deletar registro.' + #13 + E.message);
      end;
      // Sistema.conexao.ControleTransaction.rollBack;
    end;
  finally

    // Sistema.conexao.ControleTransaction.endTransaction;
  end;
end;

function TModelManager.Save(var AModel: TModel): boolean;
begin
  if AModel.Id > 0 then
    Result := doUpdate(AModel)
  else
    Result := doSave(AModel);
end;

{ TModelField }

constructor TModelField.create(const APropField: TRttiField; const AFieldAttribute: TFieldAttribute);
begin
  Contexto := TRttiContext.create;
  FFieldName := AFieldAttribute.FieldName;
  FAttibuteName := APropField.Name;
end;

function TModelField.GetValue(AModel: TModel): TValue;
begin
  try
    Tipo := Contexto.GetType(AModel.Classtype);
    FValue := Tipo.getField(AttibuteName).GetValue(AModel);
  finally
    Result := FValue;
  end;
end;

procedure TModelField.SetValue(AModel: TModel; AValue: TValue);
begin
  FValue := AValue;
  Tipo := Contexto.GetType(AModel.Classtype);
  Tipo.getField(AttibuteName).SetValue(AModel, AValue);
end;

{ TFieldAttribute }

constructor TFieldAttribute.create(const AFieldName: string);
begin
  FFieldName := AFieldName;
end;

{ TAssociationModelField }

function TAssociationModelField.GetValue(AModel: TModel): TValue;
begin
  try
    Tipo := Contexto.GetType(AModel.Classtype);
    FValue := TProxyModel<TModel>(Tipo.getField(AttibuteName).GetValue(AModel).AsObject).Key;
  finally
    Result := FValue;
  end;
end;

procedure TAssociationModelField.SetValue(AModel: TModel; AValue: TValue);
begin
  FValue := AValue;
  Tipo := Contexto.GetType(AModel.Classtype);
  TProxyModel<TModel>(Tipo.getField(AttibuteName).GetValue(AModel).AsObject).Key := AValue.AsInteger;
end;

{ TTableAttribute }

constructor TTableAttribute.create(const ATableName: string);
begin
  FTableName := ATableName;
end;

{ TProxyModel<T> }

function TProxyModel<T>.Changed: boolean;
begin
  Result := (Key <> TModel(Value).Id);
end;

constructor TProxyModel<T>.create(AFieldKey: String; AManyAssociation: boolean);
begin
  FFieldKey := AFieldKey;
  FManyAssociation := AManyAssociation;
end;

procedure TProxyModel<T>.DestroyValue;
begin
  if FValue <> nil then
    FreeAndNil(FValue);
end;

function TProxyModel<T>.GetAvailable: boolean;
begin
  Result := FLoaded and (FValue <> nil);
end;

function TProxyModel<T>.GetValue: T;
begin
  try
    if not FLoaded then
      Load;
  finally
    Result := FValue;
  end;
end;

procedure TProxyModel<T>.Load;
begin
  if Key = 0 then
    exit;

  if FManyAssociation then
    FValue := T(TControleModelManager.Instance.getModelManager(TModelClass(T)).List(FFieldKey, Key))
  else
    FValue := T(TControleModelManager.Instance.getModelManager(TModelClass(T)).Get(FFieldKey, Key));
  FLoaded := True;
end;

procedure TProxyModel<T>.SetInitialValue(AValue: T);
begin
  FValue := AValue;
end;

procedure TProxyModel<T>.SetValue(const Value: T);
begin
  try
    FValue := Value;
    FKey := TModel(FValue).Id;
    FLoaded := True;
  finally
  end;
end;

{ TModelSqlExpression }

constructor TModelSqlExpression.create(AModelManager: TModelManager);
begin
  FModelManager := AModelManager;
  { TODO -oKayo Riccelo -cObs : Pegar FDConnection que você usa para conexão com o banco de dados. }
  FConexao := TConexao.create(nil);
end;

function TModelSqlExpression.getSQLSelect(AKey: String; AValue: TValue): String;
begin
  Result := Format(SQLSelect, [getSQLFields, FModelManager.TableName, AKey, AValue.ToString]);
end;

function TModelSqlExpression.getSQLSequence: string;
begin
  Result := Format(SQLSequence, [FModelManager.SequenceName]);
end;

function TModelSqlExpression.getLoadQuery(ASql: String): TFDQuery;
begin
  try
    Result := Conexao.abrirQuery(ASql);
  except
    on E: Exception do
      raise Exception.create(Format('Erro ao tentar abrir tabela: %s', [E.message]));
  end;
end;

function TModelSqlExpression.getQuery(ASql: String): TFDQuery;
begin
  try
    Result := Conexao.criarQuery(ASql);
  except
    on E: Exception do
      raise Exception.create(Format('Erro ao tentar abrir tabela: %s', [E.message]));
  end;
end;

function TModelSqlExpression.getSQLArguments(AArgumentString: string): String;
var
  loField: TModelField;
  loBuilder: TStringBuilder;
begin
  Result := emptyStr;
  try
    loBuilder := TStringBuilder.create;
    for loField in FModelManager.ModelFields do
    begin
      if (loBuilder.ToString <> emptyStr) then
        loBuilder.append(', ');
      loBuilder.append(Format(AArgumentString, [loField.FieldName]));
    end;

  finally
    Result := loBuilder.ToString;
    FreeAndNil(loBuilder);
  end;
end;

function TModelSqlExpression.getSQLFields: String;
begin
  Result := getSQLArguments('%s');
end;

function TModelSqlExpression.getSQLParams: String;
begin
  Result := getSQLArguments(':p_%s');
end;

function TModelSqlExpression.getSQLRemove(AKey: String; AValue: TValue): string;
begin
  Result := Format(SQLRemove, [FModelManager.TableName, AKey, AValue.ToString]);
end;

function TModelSqlExpression.getSQLFieldsValues: String;
var
  loField: TModelField;
  loBuilder: TStringBuilder;
begin
  Result := emptyStr;
  try
    loBuilder := TStringBuilder.create;
    for loField in FModelManager.ModelFields do
    begin
      if (loBuilder.ToString <> emptyStr) then
        loBuilder.append(', ');
      loBuilder.append(loField.FieldName + ' = :p_' + loField.FieldName);
    end;

  finally
    Result := loBuilder.ToString;
    FreeAndNil(loBuilder);
  end;
end;

function TModelSqlExpression.getSQLUpdate(AKey: String; AValue: String): String;
begin
  Result := Format(SQLUpdate, [FModelManager.TableName, getSQLFieldsValues, AKey + ' = ' + AValue]);
end;

function TModelSqlExpression.getSQLInsert: String;
begin
  // insert into tabela (campos) values (parametros)
  Result := Format(SQLInsert, [FModelManager.TableName, getSQLFields, getSQLParams]);
end;

function TModelSqlExpression.getSQLSelect: String;
begin
  Result := Format(SQLSelect, [getSQLFields, FModelManager.TableName, '1', '1']);
end;

{ TControleModelManager }

constructor TControleModelManager.create;
begin
  FDictModelManagers := TDictionary<TModelClass, TModelManager>.create;
  FDictModelManagers.Clear;
end;

function TControleModelManager.getModelManager(AModelClass: TModelClass): TModelManager;
var
  loNewClassString: string;
begin
  Result := nil;
  if pos('<', AModelClass.ClassName) > 0 then
  begin
    loNewClassString := Copy(AModelClass.ClassName, pos('<', AModelClass.ClassName) + 1,
      Length(AModelClass.ClassName) - pos('<', AModelClass.ClassName) - 1);
    AModelClass := TModelClass(TModelUtils.getRttiClass(loNewClassString).MetaclassType);
  end;
  try
    if not FDictModelManagers.ContainsKey(AModelClass) then
      FDictModelManagers.AddOrSetValue(AModelClass, TModelManager.create(AModelClass));
  finally
    FDictModelManagers.TryGetValue(AModelClass, Result);
  end;
end;

class function TControleModelManager.Instance: TControleModelManager;
begin
  if FInstance = nil then
    FInstance := TControleModelManager.create;
  Result := FInstance;
end;

{ TModelUtils }

class function TModelUtils.getRttiClass(AClass: TModelClass): TRttiInstanceType;
var
  loRttiContext: TRttiContext;
  loRttiType: TRttiInstanceType;
begin
  Result := loRttiContext.FindType(AClass.unitName + '.' + AClass.ClassName) as TRttiInstanceType;
  if (Result = nil) then
    raise Exception.create(Format('Modelo não encontrado pelo RTTI - %s.%s', [AClass.unitName, AClass.ClassName]));
end;

class function TModelUtils.getRttiClass(AClassString: string): TRttiInstanceType;
var
  loRttiContext: TRttiContext;
  loRttiType: TRttiInstanceType;
begin
  Result := loRttiContext.FindType(AClassString) as TRttiInstanceType;
  if (Result = nil) then
    raise Exception.create(Format('Modelo não encontrado pelo RTTI - %s', [AClassString]));
end;

{ TConexao }

constructor TConexao.create(AConn: TFDConnection);
begin
  FConn := AConn;
end;

function TConexao.abrirQuery(ASql: String): TFDQuery;
begin
  Result := TFDQuery.create(nil);
  Result.Connection := Conn;
  Result.Open(ASql);
  codesite.send('Select: ', ASql);
end;

function TConexao.criarQuery(ASql: String): TFDQuery;
begin
  Result := TFDQuery.create(nil);
  Result.Connection := Conn;
  Result.SQL.Text := ASql;
end;

end.
