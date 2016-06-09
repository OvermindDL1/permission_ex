
defmodule PermissionEx.Test.Structs.User do
  @derive [Poison.Encoder]
  defstruct action: nil
end

defmodule PermissionEx.Test.Structs.Page do
  @derive [Poison.Encoder]
  defstruct action: nil
end
