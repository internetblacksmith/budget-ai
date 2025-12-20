module TransactionsHelper
  def current_params
    {
      show: params[:show],
      account: params[:account],
      category: params[:category],
      search: params[:search],
      amount: params[:amount],
      per: params[:per]
    }.compact
  end
end
