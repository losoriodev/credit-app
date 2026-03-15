defmodule CreditAppWeb.PageController do
  use CreditAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
