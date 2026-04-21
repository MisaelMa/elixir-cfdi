defmodule Sat.Captcha.Types do
  @moduledoc """
  Types for captcha solving.
  """

  @type provider :: :two_captcha | :anti_captcha | :manual

  defmodule Config do
    @moduledoc false
    defstruct [:provider, :api_key, timeout: 120_000]

    @type t :: %__MODULE__{
            provider: Sat.Captcha.Types.provider(),
            api_key: String.t() | nil,
            timeout: non_neg_integer()
          }
  end

  defmodule Challenge do
    @moduledoc false
    defstruct [:image_url, :image_base64, :site_key, :page_url]

    @type t :: %__MODULE__{
            image_url: String.t() | nil,
            image_base64: String.t() | nil,
            site_key: String.t() | nil,
            page_url: String.t() | nil
          }
  end

  defmodule Result do
    @moduledoc false
    defstruct [:text, :task_id]

    @type t :: %__MODULE__{
            text: String.t(),
            task_id: String.t() | nil
          }
  end
end
