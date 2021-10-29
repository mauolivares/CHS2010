MODULE MATRIX
IMPLICIT NONE
PRIVATE :: SWAP

! Contains Matrix Inverse, Cholesky decomposition, outerproduct, outerand, Determinant
! Rank, Colinearity check (linear independence), Jacobi rotation, quicksort
CONTAINS

FUNCTION MATINV(AIN)
! Inverts a Square Matrix
IMPLICIT NONE
REAL(8), DIMENSION(:,:), INTENT(IN) :: AIN
INTEGER, DIMENSION(SIZE(AIN,1)) :: ipiv,indxr,indxc
LOGICAL, DIMENSION(SIZE(AIN,1)) :: lpiv
REAL(8) :: pivinv,A(SIZE(AIN,1),SIZE(AIN,2)),MATINV(SIZE(AIN,1),SIZE(AIN,2))
REAL(8), DIMENSION(SIZE(AIN,1)) :: dumc
INTEGER, TARGET :: irc(2)
INTEGER :: i,l,n
INTEGER, POINTER :: irow,icol
IF (SIZE(AIN,1).NE.SIZE(AIN,2)) THEN
    PAUSE 'FATAL ERROR: matrix is not square (MATINV)***'
    STOP
END IF    
A=AIN
irow => irc(1)
icol => irc(2)
ipiv=0
n=SIZE(A,1)
DO i=1,n
    lpiv = (ipiv == 0)
    irc=MAXLOC(ABS(A),outerand(lpiv,lpiv))
    ipiv(icol)=ipiv(icol)+1
    IF (ipiv(icol) > 1) THEN
        PAUSE '***FATAL ERROR: MATINV: singular matrix (1)'
        STOP
    END IF     
    IF (irow /= icol) THEN
        CALL swap(A(irow,:),A(icol,:))
    END IF
    indxr(i)=irow
    indxc(i)=icol
    IF (a(icol,icol) == 0.0) THEN
        PAUSE '***FATAL ERROR: MATINV: singular matrix (2)'
        STOP
    END IF     
    pivinv=1.0d0/A(icol,icol)
    A(icol,icol)=1.0d0
    A(icol,:)=A(icol,:)*pivinv
    dumc=A(:,icol)
    A(:,icol)=0.0
    A(icol,icol)=pivinv
    A(1:icol-1,:)=A(1:icol-1,:)-outerprod(dumc(1:icol-1),A(icol,:))
    A(icol+1:,:)=A(icol+1:,:)-outerprod(dumc(icol+1:),A(icol,:))
END DO
DO l=n,1,-1
    CALL swap(A(:,indxr(l)),A(:,indxc(l)))
END DO
MATINV=A
END FUNCTION MATINV

FUNCTION CHOL(AIN)
IMPLICIT NONE
REAL(8), DIMENSION(:,:), INTENT(IN) :: AIN
REAL(8) :: A(SIZE(AIN,1),SIZE(AIN,2)),p(SIZE(AIN,1)),CHOL(SIZE(AIN,1),SIZE(AIN,2))
INTEGER :: i,j,n
REAL(8) :: summ
IF (SIZE(AIN,1).NE.SIZE(AIN,2)) THEN
    PAUSE 'FATAL ERROR: matrix is not square (CHOL)***'
    STOP
END IF    
A=AIN
CHOL=0.0d0
n=SIZE(A,1)
DO i=1,n
    summ=A(i,i)-DOT_PRODUCT(A(i,1:i-1),A(i,1:i-1))
    IF (summ <= 0.0d0) THEN
        PAUSE 'CHOL failed'
    END IF      
    p(i)=DSQRT(summ)
    A(i+1:n,i)=(A(i,i+1:n)-matmul(A(i+1:n,1:i-1),A(i,1:i-1)))/p(i)
    A(i,i)=p(i)
END DO
FORALL (i=1:n,j=1:n,j<=i) CHOL(i,j)=A(i,j)
END FUNCTION CHOL

FUNCTION outerand(a,b)
LOGICAL, DIMENSION(:), INTENT(IN) :: a,b
LOGICAL, DIMENSION(size(a),size(b)) :: outerand
outerand = spread(a,dim=2,ncopies=size(b)) .and. &
spread(b,dim=1,ncopies=size(a))
END FUNCTION outerand

FUNCTION outerprod(a,b)
REAL(8), DIMENSION(:), INTENT(IN) :: a,b
REAL(8), DIMENSION(size(a),size(b)) :: outerprod
outerprod = spread(a,dim=2,ncopies=size(b)) * &
spread(b,dim=1,ncopies=size(a))
END FUNCTION outerprod

FUNCTION DET(B)
! Subroutine for evaluating the determinant of a matrix using 
! the partial-pivoting Gaussian elimination scheme.
IMPLICIT NONE
REAL(8), INTENT (IN) :: B(:,:)
INTEGER :: I,J,MSGN,N,INDX(SIZE(B,1))
REAL(8) :: DET,A(SIZE(B,1),SIZE(B,1)),D
A=B
N=SIZE(B,1)
CALL ELGS(A,N,INDX)
D = 1.0
DO I = 1, N
    D = D*A(INDX(I),I)
END DO
MSGN = 1
DO I = 1, N
	DO WHILE (I.NE.INDX(I))
		MSGN = -MSGN
        J = INDX(I)
        INDX(I) = INDX(J)
        INDX(J) = J
    END DO
END DO
DET = MSGN*D
CONTAINS
SUBROUTINE ELGS (A,N,INDX)
! Subroutine to perform the partial-pivoting Gaussian elimination.
! A(N,N) is the original matrix in the input and transformed matrix
! plus the pivoting element ratios below the diagonal in the output.
! INDX(N) records the pivoting order.  Copyright (c) Tao Pang 2001.
IMPLICIT NONE
INTEGER, INTENT (IN) :: N
INTEGER :: I,J,K,K1,ITMP
INTEGER, INTENT (OUT), DIMENSION (N) :: INDX
REAL(8) :: C1,PI,PI1,PJ
REAL(8), INTENT (INOUT), DIMENSION (N,N) :: A
REAL(8), DIMENSION (N) :: C
! Initialize the index
DO I = 1, N
	INDX(I) = I
END DO
! Find the rescaling factors, one from each row
DO I = 1, N
	C1= 0.0
    DO J = 1, N
		C1 = DMAX1(C1,ABS(A(I,J)))
    END DO
    C(I) = C1
END DO
! Search the pivoting (largest) element from each column
DO J = 1, N-1
	PI1 = 0.0
    DO I = J, N
		PI = ABS(A(INDX(I),J))/C(INDX(I))
		IF (PI.GT.PI1) THEN
			PI1 = PI
			K   = I
		ENDIF
    END DO
! Interchange the rows via INDX(N) to record pivoting order
    ITMP    = INDX(J)
    INDX(J) = INDX(K)
    INDX(K) = ITMP
    DO I = J+1, N
		PJ  = A(INDX(I),J)/A(INDX(J),J)
! Record pivoting ratios below the diagonal
		A(INDX(I),J) = PJ
! Modify other elements accordingly
        DO K1 = J+1, N
			A(INDX(I),K1) = A(INDX(I),K1)-PJ*A(INDX(J),K1)
		END DO
	END DO
END DO
END SUBROUTINE ELGS
END FUNCTION DET

INTEGER FUNCTION RANK(A)
! RETURNS THE RANK OF A MATRIX
IMPLICIT NONE
REAL(8), INTENT(IN) :: A(:,:)
REAL(8) :: AA(SIZE(A,2),SIZE(A,2)),EVAL(SIZE(A,2)),TOL,EVEC(SIZE(A,2),SIZE(A,2))
INTEGER :: N,nrot
TOL=1.0d-6
N = SIZE(A,2)
AA = MATMUL(TRANSPOSE(A),A)
CALL JACOBI(AA,EVAL,EVEC,nrot)
RANK = COUNT(EVAL>TOL)
END FUNCTION RANK

SUBROUTINE sqrtmatrix(n,A,B)
INTEGER :: n
REAL(8), INTENT(IN)  :: A(n,n) 
REAL(8), INTENT(OUT) :: B(n,n)
REAL(8) :: d(n),V(n,n),AUX(n,n)
INTEGER :: nrot,i
AUX = A
call jacobi(AUX,d,V,nrot)
B = 0.0d0
do i = 1, n
	B(i,i) = dsqrt(d(i))
end do
B = MATMUL(V,MATMUL(B,TRANSPOSE(V)))
END SUBROUTINE sqrtmatrix

SUBROUTINE COLINEAR(X,IND,N)
! CHECKS FOR LINEAR INDEPENDENCE IN A MATRIX
! IT RETURNS THE INDEX OF N LINEARLY INDEPENDENT COLUMNS OF THE MATRIX IN IND(1:N)
IMPLICIT NONE
REAL(8), INTENT(IN) :: X(:,:)
INTEGER, INTENT(OUT) :: IND(SIZE(X,2)),N
INTEGER :: h,NR,NC,IN(SIZE(X,2)),R,R1,NC1,i,RS
NR = SIZE(X,1)
NC = SIZE(X,2)
N = RANK(X)
DO h = 1, NC
	IN(h) = h
END DO
IF (N==NC) THEN
	IND = IN
ELSE
	RS = N
	NC1=0
	DO h = 1, NC
		R = NC - h
		R1 = RANK(X(:,IN(h+1:NC)))
		IF ((R1<RS).and.(R1<R)) THEN
			NC1 = NC1 + 1
			IND(NC1) = h
			RS=RS-1
		ELSEIF ((R1.ge.RS).and.(R1<R)) THEN
			RS=RS
		ELSE
			IND(NC1+1:N) = IN(h+1:NC)
			EXIT
		END IF		
	END DO
END IF			
END SUBROUTINE COLINEAR

SUBROUTINE PERFECT_PREDICT_PROBIT(D,X,CON,IND,N)
! CHECKS FOR VARIABLES THAT PREDICT PERFECTLY IN A PROBIT MODEL
! IT RETURNS THE INDEX OF N COLUMNS OF THE MATRIX IN IND(1:N) MINUS THE ONES THAT PREDICT PERFECTLY
! CON IS THE LOCATION OF THE CONSTANT. IF NO CONSTANT MAKE CON=0
INTEGER, INTENT(IN) :: CON
REAL(8), INTENT(IN) :: X(:,:),D(:)
INTEGER, INTENT(OUT) :: IND(SIZE(X,2)),N
INTEGER :: c,NR,NC,N_DUMMY,SUMA,CHECK(SIZE(X,1))
NR = SIZE(X,1)
NC = SIZE(X,2)
N=0
DO c = 1, NC
	IF (c==CON) THEN
		N = N + 1
		IND(N) = c
	ELSE
		CHECK=0
		WHERE (X(:,c)==0.0d0) CHECK=1
		WHERE (X(:,c)==1.0d0) CHECK=1
		IF (SUM(CHECK)==NR) THEN
			N_DUMMY = COUNT(X(:,c)==0.0d0)
			SUMA = INT(SUM(D,X(:,c)==0.0d0))
			IF ((.NOT.SUMA==0) .AND. (.NOT.SUMA==N_DUMMY)) THEN
				N_DUMMY = COUNT(X(:,c)==1.0d0)
				SUMA = INT(SUM(D,X(:,c)==1.0d0))
				IF ((.NOT.SUMA==0) .AND. (.NOT.SUMA==N_DUMMY)) THEN
					N = N + 1
					IND(N) = c
				END IF
			END IF
		ELSE
			N = N + 1
			IND(N) = c
		END IF
	END IF
END DO
END SUBROUTINE PERFECT_PREDICT_PROBIT
							
SUBROUTINE jacobi(ain,d,v,nrot)
IMPLICIT NONE
REAL(8), DIMENSION(:,:), INTENT(IN) :: ain
REAL(8), INTENT(OUT) :: d(SIZE(AIN,1)),v(SIZE(AIN,1),SIZE(AIN,2))
INTEGER, INTENT(OUT) :: nrot
INTEGER :: i,j,ip,iq,n
REAL(8) :: c,g,h,s,sm,t,tau,theta,tresh,a(SIZE(AIN,1),SIZE(AIN,2))
REAL(8), DIMENSION(size(AIN,1)) :: b,z
LOGICAL :: upper(SIZE(AIN,1),SIZE(AIN,2))
IF (size(AIN,1).NE.size(AIN,2)) THEN
    PAUSE '***FATAL ERROR: The routine only works for square symmetric matrices (jacobi)***' 
    STOP
END IF    
n=SIZE(A,1)
A=AIN
v=0.0d0
upper=.FALSE.
FORALL(i=1:n,j=1:n,i<j) upper(i,j)=.TRUE.
FORALL(i=1:n) 
    v(i,i)=1.0D0
    b(i)=A(i,i)
END FORALL    
d=b
z=0.0d0
nrot=0
DO i=1,500
	sm=SUM(ABS(a),upper)
	IF (sm == 0.0d0) RETURN
	tresh=MERGE(0.2d0*sm/n**2,0.0d0, i < 4 )
	DO ip=1,n-1
		DO iq=ip+1,n
			g=100.0d0*abs(a(ip,iq))
			IF ((i > 4) .and. (abs(d(ip))+g == abs(d(ip))).and.(abs(d(iq))+g == abs(d(iq)))) THEN
				a(ip,iq)=0.0
			ELSEIF (abs(a(ip,iq)) > tresh) THEN
				h=d(iq)-d(ip)
				IF (abs(h)+g == abs(h)) THEN
					t=a(ip,iq)/h
				ELSE
					theta=0.5d0*h/a(ip,iq)
					t=1.0d0/(abs(theta)+sqrt(1.0d0+theta**2))
					IF (theta < 0.0) t=-t
				END IF
				c=1.0d0/dsqrt(1+t**2)
				s=t*c
				tau=s/(1.0d0+c)
				h=t*a(ip,iq)
				z(ip)=z(ip)-h
				z(iq)=z(iq)+h
				d(ip)=d(ip)-h
				d(iq)=d(iq)+h
				a(ip,iq)=0.0
				CALL jrotate(a(1:ip-1,ip),a(1:ip-1,iq))
				CALL jrotate(a(ip,ip+1:iq-1),a(ip+1:iq-1,iq))
				CALL jrotate(a(ip,iq+1:n),a(iq,iq+1:n))
				CALL jrotate(v(:,ip),v(:,iq))
				nrot=nrot+1
			END IF
		END DO
	END DO
	b=b+z
	d=b
	z=0.0
END DO
PAUSE 'too many iterations in jacobi'
STOP
CONTAINS
SUBROUTINE jrotate(a1,a2)
REAL(8), DIMENSION(:), INTENT(INOUT) :: a1,a2
REAL(8), DIMENSION(size(a1)) :: wk1
wk1=a1
a1=a1-s*(a2+a1*tau)
a2=a2+s*(wk1-a2*tau)
END SUBROUTINE jrotate
END SUBROUTINE jacobi

SUBROUTINE QUICKSORT(Xin,xout,ind)
!  Sorts xout into ascENDing order - Quicksort
REAL (8), DIMENSION (:), INTENT (in) :: Xin
INTEGER, INTENT(INOUT) :: ind(:)
REAL (8), DIMENSION (SIZE(ind)), INTENT (Out) :: xout
xout=XIN
Call SUBSOR (xout, 1, Size (xout),ind)
Call INSSORT (xout,ind)
CONTAINS
RECURSIVE SUBROUTINE SUBSOR (xout, IDEB1, IFIN1,ind)
!  Sorts xout from IDEB1 to IFIN1
REAL(8), DIMENSION (:), INTENT (InOut) :: xout
INTEGER, INTENT (In) :: IDEB1, IFIN1
	  INTEGER, INTENT(INOUT) :: ind(:)
INTEGER, PARAMETER :: NINS = 16 ! Max for insertion sort
INTEGER :: ICRS, IDEB, IDCR, IFIN, IMIL,IWRK,IPIV
REAL(8) :: XPIV, XWRK
IDEB = IDEB1
IFIN = IFIN1
!  IF we DOn't have enough values to make it worth while, we leave
!  them unsorted, and the final insertion sort will take care of them
IF ((IFIN - IDEB) > NINS) THEN
	IMIL = (IDEB+IFIN) / 2
	!  One chooses a pivot, median of 1st, last, and middle values
	IF (xout(IMIL) < xout(IDEB)) THEN
		XWRK = xout (IDEB)
		IWRK = IND (IDEB)
		xout (IDEB) = xout (IMIL)
		IND (IDEB) = IND (IMIL)
		xout (IMIL) = XWRK
		IND (IMIL) = IWRK
	END IF
	IF (xout(IMIL) > xout(IFIN)) Then
		XWRK = xout (IFIN)
		IWRK = IND(IFIN)
		xout (IFIN) = xout (IMIL)
		IND (IFIN) = IND (IMIL)
		xout (IMIL) = XWRK
		IND (IMIL) = IWRK
		IF (xout(IMIL) < xout(IDEB)) Then
			XWRK = xout (IDEB)
			IWRK = IND (IDEB)
			xout (IDEB) = xout (IMIL)
			IND (IDEB) = IND (IMIL)
			xout (IMIL) = XWRK
			IND (IMIL) = IWRK
		END IF
	END IF
	XPIV = xout (IMIL)
	IPIV = IND (IMIL)
	!  One exchanges values to put those > pivot in the END and
	!  those <= pivot at the beginning
	ICRS = IDEB
	IDCR = IFIN
	ECH2: DO
		DO
			ICRS = ICRS + 1
			IF (ICRS >= IDCR) Then
			!  the first  >  pivot is IDCR
			!  the last   <= pivot is ICRS-1
			!  Note: IF one arrives here on the first iteration, then
			!  the pivot is the maximum of the set, the last value is equal
			!  to it, and one can reduce by one the size of the set to process,
			!  as IF xout (IFIN) > XPIV
				Exit ECH2
			END IF
			IF (xout(ICRS) > XPIV) Exit
		END DO
		DO
			IF (xout(IDCR) <= XPIV) Exit
			IDCR = IDCR - 1
			IF (ICRS >= IDCR) Then
			!  The last value < pivot is always ICRS-1
				Exit ECH2
			END IF
		END DO
		XWRK = xout (IDCR)
		IWRK = IND (IDCR)
		xout (IDCR) = xout (ICRS)
		IND (IDCR) = IND (ICRS)
		xout (ICRS) = XWRK
		IND (ICRS) = IWRK
	END DO ECH2
!  One now sorts each of the two sub-intervals
	Call SUBSOR (xout, IDEB1, ICRS-1,IND)
	Call SUBSOR (xout, IDCR, IFIN1,IND)
END IF
RETURN
END SUBROUTINE SUBSOR
END SUBROUTINE QUICKSORT

SUBROUTINE INSSORT (xout,IND)
!  Sorts xout into increasing order (Insertion sort)
REAL(8), DIMENSION (:), INTENT (InOut) :: xout
INTEGER, INTENT(INOUT) :: ind(:)
INTEGER :: ICRS, IDCR,IWRK
REAL(8) :: XWRK
DO ICRS = 2, Size (xout)
	XWRK = xout (ICRS)
	IWRK = IND (ICRS)
	IF (XWRK >= xout(ICRS-1)) Cycle
	xout (ICRS) = xout (ICRS-1)
	IND (ICRS) = IND (ICRS-1)
	DO IDCR = ICRS - 2, 1, - 1
		IF (XWRK >= xout(IDCR)) Exit
		xout (IDCR+1) = xout (IDCR)
		IND (IDCR+1) = IND (IDCR)
	END DO
	xout (IDCR+1) = XWRK
	IND (IDCR+1) = IWRK
END DO
RETURN
END SUBROUTINE INSSORT

SUBROUTINE swap(a,b)
REAL(8), INTENT(INOUT) :: a(:),b(:)
REAL(8) :: dum(SIZE(A))
dum=a
a=b
b=dum
END SUBROUTINE swap

END MODULE MATRIX