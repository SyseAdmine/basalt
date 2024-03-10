# from tensor import TensorShape
# from random import rand
# from math import sqrt
# from python import Python
# from testing import assert_almost_equal

# from dainemo import GRAPH
# from dainemo.nn.layers import Layer
# from dainemo.autograd.node import Node
# from dainemo.autograd.ops.basics import DOT, ADD, RESHAPE
# from dainemo.autograd.ops.conv import CONV2D
# import dainemo.nn as nn
# from dainemo.utils.tensorutils import rand_uniform
# from test_tensorutils import assert_tensors_equal

# from test_conv import to_numpy, to_tensor

# alias dtype = DType.float32


# struct Linear(Layer):
#     """
#     A fully connected layer.
#     """

#     var weights: Node[dtype]
#     var bias: Node[dtype]

#     fn __init__(inout self, owned weights: Tensor[dtype], owned bias: Tensor[dtype]):
#         self.weights = Node[dtype](weights, trainable=True, param=True)
#         self.bias = Node[dtype](bias, trainable=True, param=True)
#         GRAPH.add_node(self.weights)
#         GRAPH.add_node(self.bias)

#     fn forward(self, inputs: Node[dtype]) -> Node[dtype]:
#         """
#         Forward pass of the linear layer.
#         """
#         var weights = GRAPH.graph[GRAPH.get_node_idx(self.weights.uuid)]
#         var bias = GRAPH.graph[GRAPH.get_node_idx(self.bias.uuid)]

#         var res = DOT.forward(inputs, weights)
#         return ADD.forward(res, bias)

#     fn __call__(self, inputs: Node[dtype]) -> Node[dtype]:
#         return self.forward(inputs)


# # <------------CONV2D------------>
# struct Conv2d[
#     padding: StaticIntTuple[2] = 0,
#     stride: StaticIntTuple[2] = 1,
#     dilation: StaticIntTuple[2] = 1,
# ](Layer):
#     """
#     A 2D Convolution Layer.

#     Parameters
#         inputs.shape     [batch, in_channels, X, Y]
#         kernel.shape     [out_channels, in_channels, X, Y] (or weights)
#         bias.shape       [out_channels].
#         output.shape     [batch, out_channels, X, Y].
#     """

#     var weights: Node[dtype]
#     var bias: Node[dtype]

#     fn __init__(inout self, owned weights: Tensor[dtype], owned bias: Tensor[dtype]):
#         self.weights = Node[dtype](weights, trainable=True, param=True)
#         self.bias = Node[dtype](bias, trainable=True, param=True)
#         GRAPH.add_node(self.weights)
#         GRAPH.add_node(self.bias)

#     fn forward(self, inputs: Node[dtype]) -> Node[dtype]:
#         """
#         Forward pass of the convolution layer.
#         """
#         var weights = GRAPH.graph[GRAPH.get_node_idx(self.weights.uuid)]
#         var bias = GRAPH.graph[GRAPH.get_node_idx(self.bias.uuid)]

#         return CONV2D.forward[padding, stride, dilation](inputs, weights, bias)

#     fn __call__(self, inputs: Node[dtype]) -> Node[dtype]:
#         return self.forward(inputs)


# struct CNN:
#     var l1: Conv2d[2, 1]
#     var l2: nn.ReLU
#     var l3: nn.MaxPool2d[2]
#     var l4: Conv2d[2, 1]
#     var l5: nn.ReLU
#     var l6: nn.MaxPool2d[2]
#     var l7: Linear

#     fn __init__(
#         inout self,
#         conv1_weights: Tensor[dtype],
#         conv1_bias: Tensor[dtype],
#         conv2_weights: Tensor[dtype],
#         conv2_bias: Tensor[dtype],
#         linear1_weights: Tensor[dtype],
#         linear1_bias: Tensor[dtype],
#     ):
#         self.l1 = Conv2d[2, 1](conv1_weights, conv1_bias)
#         self.l2 = nn.ReLU()
#         self.l3 = nn.MaxPool2d[kernel_size=2]()
#         self.l4 = Conv2d[2, 1](conv2_weights, conv2_bias)
#         self.l5 = nn.ReLU()
#         self.l6 = nn.MaxPool2d[kernel_size=2]()
#         self.l7 = Linear(linear1_weights, linear1_bias)

#     fn forward(inout self, x: Tensor[dtype]) -> Node[dtype]:
#         var output = self.l1(Node[dtype](x))
#         output = self.l2(output)
#         output = self.l3(output)
#         output = self.l4(output)
#         output = self.l5(output)
#         output = self.l6(output)
#         output = RESHAPE.forward(output, TensorShape(output.tensor.dim(0), 32*7*7))
#         output = self.l7(output)
#         return output


# fn run_mojo(
#     epochs: Int,
#     learning_rate: FloatLiteral,
#     inputs: Tensor[dtype],
#     labels: Tensor[dtype],
#     conv1_weights: Tensor[dtype],
#     conv1_bias: Tensor[dtype],
#     conv2_weights: Tensor[dtype],
#     conv2_bias: Tensor[dtype],
#     linear1_weights: Tensor[dtype],
#     linear1_bias: Tensor[dtype],
# ) -> DynamicVector[Float32]:
#     var cnn = CNN(
#         conv1_weights,
#         conv1_bias,
#         conv2_weights,
#         conv2_bias,
#         linear1_weights,
#         linear1_bias,
#     )

#     var loss_func = nn.CrossEntropyLoss()
#     # var loss_func = nn.MSELoss()
#     var optim = nn.optim.Adam(lr=learning_rate)

#     var losses = DynamicVector[Float32]()

#     for i in range(epochs):
#         var output = cnn.forward(inputs)
#         var loss = loss_func(output, labels)

#         # Backward pass
#         optim.zero_grad()
#         loss.backward()
#         optim.step()

#         losses.push_back(loss.tensor[0])

#     return losses


# fn run_torch(
#     epochs: Int,
#     learning_rate: FloatLiteral,
#     inputs: Tensor,
#     labels: Tensor,
#     owned conv1_weights: Tensor,
#     owned conv1_bias: Tensor,
#     owned conv2_weights: Tensor,
#     owned conv2_bias: Tensor,
#     owned linear1_weights: Tensor,
#     owned linear1_bias: Tensor,
# ) -> DynamicVector[Float32]:
#     var out: DynamicVector[Float32] = DynamicVector[Float32]()

#     try:
#         var torch = Python.import_module("torch")
#         var F = Python.import_module("torch.nn.functional")
#         var np = Python.import_module("numpy")
#         Python.add_to_path("./test")
#         var cnn_class = Python.import_module("test_cnn_class_torch")

#         var inputs = torch.from_numpy(to_numpy(inputs)).trainable_(True)
#         var labels = torch.from_numpy(to_numpy(labels)).trainable_(True)

#         var conv1_weights = torch.from_numpy(to_numpy(conv1_weights)).trainable_(
#             True
#         )
#         var conv1_bias = torch.from_numpy(to_numpy(conv1_bias)).trainable_(True)
#         var conv2_weights = torch.from_numpy(to_numpy(conv2_weights)).trainable_(
#             True
#         )
#         var conv2_bias = torch.from_numpy(to_numpy(conv2_bias)).trainable_(True)
#         var linear1_weights = torch.from_numpy(
#             to_numpy(linear1_weights)
#         ).trainable_(True)
#         var linear1_bias = torch.from_numpy(to_numpy(linear1_bias)).trainable_(True)

#         var cnn = cnn_class.CNN(
#             conv1_weights,
#             conv1_bias,
#             conv2_weights,
#             conv2_bias,
#             linear1_weights,
#             linear1_bias,
#         )

#         # var loss_func = cnn_class.CrossEntropyLoss2()
#         var loss_func = torch.nn.CrossEntropyLoss()
#         var optimizer = torch.optim.Adam(cnn.parameters(), learning_rate)

#         for i in range(epochs):
#             var output = cnn.forward(inputs)
#             var loss = loss_func(output, labels)

#             _ = optimizer.zero_grad()
#             _ = loss.backward()
#             _ = optimizer.step()

#             out.push_back(to_tensor(loss)[0])

#         return out

#     except e:
#         print("Error importing torch")
#         print(e)
#         return out


# fn he_uniform(shape: TensorShape, fan_in: Int) -> Tensor[dtype]:
#     """
#     Returns a tensor with random values between -h and h.
#     """
#     alias nelts = simdwidthof[dtype]()
#     var k: SIMD[dtype, 1] = 1.0 / fan_in
#     var h = sqrt(k)
#     return rand_uniform[dtype, nelts](shape, -h, h)


# fn main():
#     var learning_rate = 1e-3
#     var epochs = 20
#     var batch_size = 4

#     var inputs = rand[dtype](batch_size, 1, 28, 28)
#     var labels = Tensor[dtype](batch_size, 10) # one-hot encoded (probabilities)
#     for i in range(4):
#         labels[i * 10 + i] = 1.0

#     var conv1_weights = he_uniform(TensorShape(16, 1, 5, 5), 1)
#     var conv1_bias = Tensor[dtype](16)

#     var conv2_weights = he_uniform(TensorShape(32, 16, 5, 5), 2)
#     var conv2_bias = Tensor[dtype](32)

#     var linear1_weights = he_uniform(TensorShape(32 * 7 * 7, 10), 32 * 7 * 7)
#     var linear1_bias = Tensor[dtype](10)

#     var losses_mojo = run_mojo(
#         epochs,
#         learning_rate,
#         inputs,
#         labels,
#         conv1_weights,
#         conv1_bias,
#         conv2_weights,
#         conv2_bias,
#         linear1_weights,
#         linear1_bias,
#     )

#     var losses_torch = run_torch(
#         epochs,
#         learning_rate,
#         inputs,
#         labels,
#         conv1_weights,
#         conv1_bias,
#         conv2_weights,
#         conv2_bias,
#         linear1_weights,
#         linear1_bias,
#     )

#     for i in range(epochs):
#         print("loss_mojo: ", losses_mojo[i], " loss_torch: ", losses_torch[i])

#     # for i in range(epochs):
#     #     var loss_mojo = losses_mojo[i]
#     #     var loss_torch = losses_torch[i]
#     #     print("loss_mojo: ", loss_mojo, " loss_torch: ", loss_torch)
#     #     try:
#     #         assert_almost_equal(loss_mojo, loss_torch, 1e-5)
#     #     except e:
#     #         print("Losses not equal")
#     #         print(e)
#     #         break