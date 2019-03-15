
vec = [smooth(vec(:,1),3) smooth(vec(:,2),3)];
da = 0;

N = length(vec);

lag = 0;
d = zeros(N, 1);

for n = 1:N
    for k = 1:N - lag
        A = [vec(k,1) vec(k,2)];
        B = [vec(k + lag,1) vec(k + lag,2)];
        cosvec = dot(A,B)./(norm(A).*norm(B));
        % sum cosine values
        d(n,1) = d(n,1) + cosvec;
    end
    lag = lag + 1;
    da(1:length(d),1) = d(:,1) / N;
end