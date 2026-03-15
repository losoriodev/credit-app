defmodule CreditApp.Accounts.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :credit_app,
    module: CreditApp.Accounts.Guardian,
    error_handler: CreditApp.Accounts.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
