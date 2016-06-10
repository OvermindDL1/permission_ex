
defmodule PermissionEx.Test.Structs.User do
  @moduledoc false
  # @derive [Poison.Encoder]
  defstruct name: nil
end

defmodule PermissionEx.Test.Structs.Page do
  @moduledoc false
  # @derive [Poison.Encoder]
  defstruct action: nil
end

defmodule PermissionEx.Test.Structs.PageReq do
  @moduledoc false
  # @derive [Poison.Encoder]
  defstruct action: nil
end

defmodule PermissionEx.Test.Structs.PagePerm do
  @moduledoc false
  # @derive [Poison.Encoder]
  defstruct action: nil
end
