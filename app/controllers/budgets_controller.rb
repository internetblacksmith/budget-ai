class BudgetsController < ApplicationController
  before_action :set_budget, only: %i[update destroy]

  def index
    @budgets = Budget.order(:category)
  end

  def create
    @budget = Budget.new(budget_params)

    if @budget.save
      respond_to do |format|
        format.html { redirect_to budgets_path, notice: "Budget for #{@budget.category} created." }
        format.json { render json: @budget, status: :created }
      end
    else
      respond_to do |format|
        format.html do
          @budgets = Budget.order(:category)
          flash.now[:alert] = @budget.errors.full_messages.join(", ")
          render :index, status: :unprocessable_entity
        end
        format.json { render json: { errors: @budget.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @budget.update(budget_params)
      respond_to do |format|
        format.html { redirect_to budgets_path, notice: "Budget for #{@budget.category} updated." }
        format.json { render json: @budget }
      end
    else
      respond_to do |format|
        format.html { redirect_to budgets_path, alert: @budget.errors.full_messages.join(", ") }
        format.json { render json: { errors: @budget.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    category = @budget.category
    @budget.destroy
    respond_to do |format|
      format.html { redirect_to budgets_path, notice: "Budget for #{category} removed." }
      format.json { head :no_content }
    end
  end

  private

  def set_budget
    @budget = Budget.find(params[:id])
  end

  def budget_params
    params.require(:budget).permit(:category, :monthly_limit, :period_start, :period_end, :notes)
  end
end
