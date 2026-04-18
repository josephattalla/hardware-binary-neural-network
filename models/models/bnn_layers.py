import torch
import torch.nn as nn
from torch.nn import Module, Conv2d, Linear
from torch.nn.functional import linear, conv2d


__all__ = ['BNNLinear', 'BNNConv2d']




def Binarize(tensor,quant_mode='bin'):
    if quant_mode=='det':
        return tensor.sign()
    if quant_mode=='bin':
        return (tensor>=0).to(tensor.dtype)*2-1
    else:
        return tensor.add_(1).div_(2).add_(torch.rand(tensor.size()).add(-0.5)).clamp_(0,1).round().mul_(2).add_(-1)
    

# def Quantize(tensor):
#     tensor.apply_(lambda val: 2*val - 1)


class BNNLinear(Linear):

    def __init__(self, *kargs, **kwargs):
        super(BNNLinear, self).__init__(*kargs, **kwargs)
        self.register_buffer('weight_org', self.weight.data.clone())

    def forward(self, input):

        if (input.size(1) != 784) and (input.size(1) != 3072):
            input.data=Binarize(input.data)
        else:
            input.data = Binarize(2 * input.data - 1)  # map [0,1] → {-1,+1}
            
        self.weight.data=Binarize(self.weight_org)
        out = linear(input, self.weight)

        if not self.bias is None:
            self.bias.org=self.bias.data.clone()
            out += self.bias.view(1, -1).expand_as(out)

        return out
    

class BNNConv2d(Conv2d):

    def __init__(self, *kargs, **kwargs):
        super(BNNConv2d, self).__init__(*kargs, **kwargs)
        self.register_buffer('weight_org', self.weight.data.clone())

    def forward(self, input):
        if input.size(1) != 3:
            input.data = Binarize(input.data)
        
        self.weight.data=Binarize(self.weight_org)
        

        out = conv2d(input, self.weight, None, self.stride,
                                   self.padding, self.dilation, self.groups)

        if not self.bias is None:
            self.bias.org=self.bias.data.clone()
            out += self.bias.view(1, -1, 1, 1).expand_as(out)

        return out


# class BinarizeSTE(torch.autograd.Function):
#     """Binarize with Straight-Through Estimator for gradients."""
#     @staticmethod
#     def forward(ctx, x):
#         ctx.save_for_backward(x)
#         return x.sign().clamp(min=-1)  # handles 0 → -1

#     @staticmethod
#     def backward(ctx, grad_output):
#         x, = ctx.saved_tensors
#         # STE: pass gradient through where |x| <= 1
#         grad = grad_output.clone()
#         grad[x.abs() > 1] = 0
#         return grad

# def binarize(x):
#     return BinarizeSTE.apply(x)


# class BNNLinear(Linear):
#     def __init__(self, *kargs, **kwargs):
#         super().__init__(*kargs, **kwargs)
#         # weight_org holds the real-valued "latent" weights
#         self.weight_org = nn.Parameter(self.weight.data.clone())
#         # weight itself won't be trained — we only use weight_org
#         self.weight.requires_grad_(False)

#     def forward(self, x):
#         # Binarize weights via STE (gradients flow to weight_org)
#         binary_weight = binarize(self.weight_org)
#         return linear(x, binary_weight, self.bias)


# class BNNConv2d(Conv2d):
#     def __init__(self, *kargs, **kwargs):
#         super().__init__(*kargs, **kwargs)
#         self.weight_org = nn.Parameter(self.weight.data.clone())
#         self.weight.requires_grad_(False)

#     def forward(self, x):
#         binary_weight = binarize(self.weight_org)
#         return conv2d(x, binary_weight, self.bias,
#                       self.stride, self.padding, self.dilation, self.groups)