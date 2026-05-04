defmodule Cfdi.Validador.Types do
  @moduledoc false

  defmodule ValidationIssue do
    @moduledoc false
    @enforce_keys [:message]
    defstruct [:rule_id, :message, :path]

    @type t :: %__MODULE__{
            rule_id: atom() | nil,
            message: String.t(),
            path: String.t() | nil
          }
  end

  defmodule ValidationResult do
    @moduledoc false
    defstruct valid?: true, issues: []

    @type t :: %__MODULE__{
            valid?: boolean(),
            issues: [ValidationIssue.t()]
          }
  end

  defmodule ValidationRule do
    @moduledoc false
    @enforce_keys [:id, :check]
    defstruct [:id, :description, :check]

    @type t :: %__MODULE__{
            id: atom(),
            description: String.t() | nil,
            check: (CfdiData.t() -> :ok | {:error, ValidationIssue.t()})
          }
  end

  defmodule CfdiData do
    @moduledoc false
    defstruct [:document]

    @type t :: %__MODULE__{
            document: {String.t(), [{String.t(), String.t()}], list()}
          }
  end
end
