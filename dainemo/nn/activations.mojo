# from tensor import Tensor

# from dainemo.autograd.node import Node
# from dainemo.autograd.ops.basics import SUM, SUB, DIV, EXP, MAX, LOG
# import dainemo.autograd.ops.mlops
from dainemo import Graph, Symbol, OP
from dainemo.autograd.attributes import Attribute, AttributeVector

# '''Activation functions.'''

# <------------RELU------------>
fn ReLU(inout g: Graph, input: Symbol) -> Symbol:
    return g.op(OP.RELU, input)


# <------------SIGMOID------------>
fn Sigmoid(inout g: Graph, input: Symbol) -> Symbol:
    return g.op(OP.SIGMOID, input)


# <------------TANH------------>
fn Tanh(inout g: Graph, input: Symbol) -> Symbol:
    return g.op(OP.TANH, input)


# <------------SOFTMAX------------>
fn Softmax(inout g: Graph, input: Symbol, axis: Int) -> Symbol:
    # softmax: exp(x_i) / sum(exp(x_j))
    # stable softmax: exp(x_i - max(x_j)) / sum(exp(x_j - max(x_j)))

    var max_values = g.op(OP.MAX, input, attributes=AttributeVector(Attribute("axis", axis)))
    var input_minus_max = g.op(OP.SUB, input, max_values)
    var exp_values = g.op(OP.EXP, input_minus_max)
    var sum_values = g.op(OP.SUM, exp_values, attributes=AttributeVector(Attribute("axis", axis)))

    return g.op(OP.DIV, exp_values, sum_values)


# <------------LOGSOFTMAX------------>
fn LogSoftmax(inout g: Graph, input: Symbol, axis: Int) -> Symbol:
    # stable logsoftmax: log(exp(x_i - max(x_j)) / sum(exp(x_j - max(x_j))))
    # stable logsoftmax: x_i - max(x_j) - log(sum(exp(x_j - max(x_j))))

    var max_values = g.op(OP.MAX, input, attributes=AttributeVector(Attribute("axis", axis)))
    var input_minus_max = g.op(OP.SUB, input, max_values)
    var exp_values = g.op(OP.EXP, input_minus_max)
    var sum_values = g.op(OP.SUM, exp_values, attributes=AttributeVector(Attribute("axis", axis)))
    var log_values = g.op(OP.LOG, sum_values)

    return g.op(OP.SUB, input_minus_max, log_values)


# # <------------LEAKYRELU------------>